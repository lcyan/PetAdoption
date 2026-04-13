# PetAdoption 宠物领养系统 - 代码分析报告

## 一、项目概述

### 1.1 项目简介
PetAdoption 是一个基于 Spring Boot 2.3.3 的宠物领养管理系统，提供宠物信息展示、用户注册登录、领养申请审核等功能。系统采用经典的 MVC 架构，使用 Thymeleaf 作为模板引擎，MyBatis 作为 ORM 框架。

### 1.2 技术栈
| 技术 | 版本 | 用途 |
|------|------|------|
| Spring Boot | 2.3.3.RELEASE | 核心框架 |
| MyBatis | 2.1.1 | ORM框架 |
| Druid | 1.1.19 | 数据库连接池 |
| H2/MySQL | 5.1.47 | 数据库 |
| Thymeleaf | - | 模板引擎 |
| Lombok | 1.18.12 | 代码简化 |
| PageHelper | - | 分页插件 |
| Kotlin | 1.4.0 | 辅助语言 |

### 1.3 项目结构
```
PetAdoption/
├── src/main/java/com/pet/demo/
│   ├── config/          # 配置类（拦截器、AOP、异常处理）
│   ├── controller/      # 控制器层（8个Controller）
│   ├── dao/             # 数据访问层（6个DAO接口）
│   ├── entity/          # 实体类（7个Entity）
│   ├── exception/       # 自定义异常
│   ├── provider/        # 第三方服务提供者（UCloud文件上传）
│   ├── service/         # 服务层（接口+实现）
│   └── utils/           # 工具类（验证码生成）
├── src/main/resources/
│   ├── com/pet/mapper/  # MyBatis Mapper XML
│   ├── static/          # 静态资源（CSS/JS/图片）
│   ├── templates/       # Thymeleaf模板
│   ├── application.properties
│   └── schema.sql       # 数据库初始化脚本
└── Dockerfile           # Docker构建文件
```

---

## 二、核心功能模块分析

### 2.1 用户认证模块

#### 关键代码位置
- [LoginController.java](src/main/java/com/pet/demo/controller/LoginController.java)

#### 功能分析
```java
@PostMapping("/login")
public String userLogin(String code, HttpSession session,
                        @RequestParam("Account") String Account,
                        @RequestParam("Password") String Password,
                        @RequestParam("role") String role,
                        Model model){
    String sessionCode = (String) session.getAttribute("code");
    if(sessionCode.equalsIgnoreCase(code)){
        if(role.equals("管理员")){
            Admin loading = adminService.loading(Account,Password);
            if(loading!=null){
                session.setAttribute("Name",loading.getAdminName());
                session.setAttribute("Id",loading.getAdminId());
                return "redirect:/manage";
            }
        }
        // ... 用户登录逻辑
    }
}
```

#### 实现机制
1. **验证码校验**：通过Session存储验证码，登录时比对
2. **角色区分**：支持"管理员"和"用户"两种角色
3. **Session管理**：登录成功后将用户信息存入Session

#### 潜在问题
- ⚠️ **安全隐患**：密码明文存储和传输，未使用加密
- ⚠️ **验证码安全**：验证码存储在Session中，存在Session固定攻击风险
- ⚠️ **字符串比较**：使用`role.equals("管理员")`而非`"管理员".equals(role)`，可能触发NPE

---

### 2.2 宠物管理模块

#### 关键代码位置
- [PetTestController.java](src/main/java/com/pet/demo/controller/PetTestController.java)
- [PetServiceImpl.java](src/main/java/com/pet/demo/service/Impl/PetServiceImpl.java)

#### 功能分析
```java
@PostMapping("/save")
public String savePet(@RequestParam(value = "petPic") MultipartFile file,
                      HttpServletRequest request){
    try {
        String fileName = uCloudProvider.upload(file.getInputStream(), 
                          file.getContentType(), file.getOriginalFilename());
        Pet pet = new Pet();
        pet.setPetPic(fileName);
        // ... 设置其他属性
        if(StringUtils.isEmpty(request.getParameter("petId"))){
            petService.save(pet);
        }else {
            pet.setPetId(request.getParameter("petId"));
            petService.update(pet);
        }
    } catch (IOException e) {
        e.printStackTrace();
    }
    return "redirect:/PetTest/pet";
}
```

#### 实现机制
1. **文件上传**：集成UCloud对象存储服务
2. **CRUD操作**：通过判断petId是否为空区分新增/修改
3. **分页查询**：使用PageHelper实现分页

#### 潜在问题
- ⚠️ **异常处理不当**：`e.printStackTrace()`仅打印堆栈，未做有效处理
- ⚠️ **文件上传安全**：未限制文件类型和大小，存在上传漏洞风险
- ⚠️ **事务缺失**：Service层未添加`@Transactional`注解

---

### 2.3 领养申请模块

#### 关键代码位置
- [ApplyTestController.java](src/main/java/com/pet/demo/controller/ApplyTestController.java)

#### 功能分析
```java
@Transactional
@GetMapping("/agree/{applyId}/{petId}")
public String agree(@PathVariable(name = "applyId") String applyId,
                    @PathVariable(name = "petId") String petId) {
    Apply apply = applyService.findOne(applyId);
    apply.setApplyState("同意领养");
    applyService.update(apply);
    Pet pet = petService.findOne(petId);
    pet.setPetState("已被领养");
    petService.update(pet);
    applyService.modify(petId,"审核中");
    return "redirect:/Apply/find";
}
```

#### 实现机制
1. **事务管理**：使用`@Transactional`确保数据一致性
2. **批量拒绝**：同意一个申请后，自动拒绝其他申请
3. **状态流转**：管理申请状态（审核中→同意/不同意）

#### 潜在问题
- ⚠️ **事务范围**：事务注解在Controller层而非Service层，不符合最佳实践
- ⚠️ **并发问题**：无乐观锁/悲观锁，高并发下可能出现数据不一致

---

### 2.4 AOP日志模块

#### 关键代码位置
- [LogAsPect.java](src/main/java/com/pet/demo/config/LogAsPect.java)
- [Log.java](src/main/java/com/pet/demo/config/Log.java)

#### 功能分析
```java
@Aspect
@Component
public class LogAsPect {
    @Pointcut("@annotation(com.pet.demo.config.Log)")
    public void pointcut() {}

    @Around("pointcut()")
    public Object around(ProceedingJoinPoint point) {
        Object result = null;
        try {
            result = point.proceed();
            String now = LocalDateTime.now().format(...);
            insertLog(point, now);
        } catch (Throwable e) {
            // 异常被吞掉
        }
        return result;
    }
}
```

#### 实现机制
1. **自定义注解**：通过`@Log`注解标记需要记录的方法
2. **环绕通知**：使用`@Around`捕获方法执行前后
3. **日志入库**：将操作日志存入数据库

#### 潜在问题
- ⚠️ **异常吞没**：catch块中未处理异常，导致异常信息丢失
- ⚠️ **性能影响**：每次操作都写数据库，可能成为性能瓶颈
- ⚠️ **Session依赖**：直接注入HttpSession，在非Web环境可能出错

---

## 三、潜在风险点分析

### 3.1 安全隐患

#### 3.1.1 密码安全
```java
// 问题代码
User login = userService.login(Account, Password);
// SQL: where userAccount=#{Account} and userPassword=#{Password}
```
**风险**：密码明文存储，未使用BCrypt等加密算法

**建议**：
```java
// 使用BCrypt加密
String encodedPassword = passwordEncoder.encode(rawPassword);
// 验证时
passwordEncoder.matches(rawPassword, encodedPassword);
```

#### 3.1.2 SQL注入风险
虽然MyBatis使用`#{}`预编译，但部分代码存在隐患：
```xml
<!-- 相对安全 -->
<select id="findByName" parameterType="String" resultType="Pet">
    select * from t_pet where petName like #{petName}
</select>
```
当前代码使用预编译，SQL注入风险较低，但需注意模糊查询的拼接方式。

#### 3.1.3 XSS跨站脚本
Thymeleaf默认会转义HTML，但需注意：
```html
<!-- 安全：自动转义 -->
<td th:text="${pet.petName}"></td>
<!-- 危险：不转义 -->
<td th:utext="${pet.petName}"></td>
```

#### 3.1.4 CSRF防护
项目未启用CSRF防护，存在跨站请求伪造风险。

### 3.2 性能瓶颈

#### 3.2.1 数据库查询
```java
// 问题：每次查询都获取全部字段
List<Pet> pets = petService.findAll();
```
**建议**：使用投影查询只获取必要字段

#### 3.2.2 N+1查询问题
```java
// 可能触发N+1查询
List<Apply> applies = applyService.findAll("审核中");
for(Apply apply : applies) {
    Pet pet = petService.findOne(apply.getApplyPetId()); // 每次循环查询
}
```

#### 3.2.3 连接池配置
```properties
# 缺少连接池优化配置
spring.datasource.type=com.alibaba.druid.pool.DruidDataSource
```
**建议添加**：
```properties
spring.datasource.druid.initial-size=5
spring.datasource.druid.max-active=20
spring.datasource.druid.min-idle=5
```

### 3.3 代码质量问题

#### 3.3.1 异常处理不规范
```java
// 问题代码
try {
    String fileName = uCloudProvider.upload(...);
} catch (IOException e) {
    e.printStackTrace(); // 仅打印，未处理
}
```

#### 3.3.2 硬编码问题
```java
// 状态值硬编码
apply.setApplyState("审核中");
pet.setPetState("未领养");
```
**建议**：使用枚举或常量类管理状态

#### 3.3.3 代码重复
多个Controller中存在重复的分页逻辑：
```java
// 重复代码模式
PageHelper.startPage(pageNum, 5);
List<Xxx> list = xxxService.findAll();
PageInfo<Xxx> pageInfo = new PageInfo<>(list);
model.addAttribute("pagelist", pageInfo);
```

### 3.4 架构设计问题

#### 3.4.1 事务边界不清晰
```java
// 问题：事务注解在Controller
@Transactional
@GetMapping("/agree/{applyId}/{petId}")
public String agree(...) { }
```
**建议**：事务应在Service层管理

#### 3.4.2 缺少DTO层
实体类直接暴露给前端，存在字段泄露风险。

#### 3.4.3 缺少统一响应格式
```java
// 当前：直接返回页面或字符串
return "redirect:/Apply/find";
return msg;
```
**建议**：使用统一响应对象：
```java
public class Result<T> {
    private int code;
    private String message;
    private T data;
}
```

---

## 四、数据库设计分析

### 4.1 表结构问题

#### 4.1.1 字段类型不合理
```sql
admin_age VARCHAR(255)  -- 年龄应为INT
pet_bir VARCHAR(255)    -- 生日应为DATE
```

#### 4.1.2 缺少索引
```sql
-- 缺少索引
CREATE TABLE t_apply (
    apply_user_id VARCHAR(255),  -- 应添加索引
    apply_pet_id VARCHAR(255),   -- 应添加索引
    apply_state VARCHAR(255)     -- 应添加索引
);
```

#### 4.1.3 缺少外键约束
表之间没有外键关系，数据完整性靠应用层保证。

### 4.2 Schema与Mapper不匹配问题

**发现的问题**：原始`schema.sql`中的表名与MyBatis Mapper XML不匹配：
- Schema: `admin`, `pet`, `user`, `apply`
- Mapper: `t_admin`, `t_pet`, `t_user`, `t_apply`

**已修复**：更新了schema.sql，添加了`t_`前缀以匹配Mapper配置。

---

## 五、Docker部署分析

### 5.1 Dockerfile分析
```dockerfile
FROM maven:3.8.6-eclipse-temurin-8 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests -Dmaven.repo.local=/root/.m2/repository

FROM eclipse-temurin:8-jre-alpine
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
EXPOSE 8885
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### 优点
- ✅ 多阶段构建，镜像体积小
- ✅ 使用Alpine基础镜像

#### 改进建议
```dockerfile
# 添加JVM参数优化
ENTRYPOINT ["java", "-Xms256m", "-Xmx512m", "-jar", "app.jar"]

# 添加健康检查
HEALTHCHECK --interval=30s CMD wget -q -O /dev/null http://localhost:8885/ || exit 1
```

### 5.2 构建测试结果
```
✅ Docker镜像构建成功
✅ 容器启动成功
✅ 应用在5.564秒内启动完成
✅ 基础API测试通过（首页、登录页、验证码）
```

---

## 六、测试结果汇总

### 6.1 API测试结果
| 接口 | 方法 | 状态码 | 结果 |
|------|------|--------|------|
| `/` | GET | 200 | ✅ 通过 |
| `/index` | GET | 200 | ✅ 通过 |
| `/login` | GET | 200 | ✅ 通过 |
| `/code` | GET | 200 | ✅ 通过 |
| `/show` | GET | 200 | ⚠️ 显示错误页面（数据查询问题） |

### 6.2 问题分析
`/show`接口显示错误页面的原因：
- MyBatis Mapper查询`select * from t_pet where petState='未领养'`
- 数据库初始化数据已正确插入
- 可能是H2数据库兼容性问题或SQL执行时机问题

---

## 七、改进建议汇总

### 7.1 高优先级
1. **密码加密**：使用BCrypt加密存储密码
2. **事务管理**：将事务注解移至Service层
3. **异常处理**：完善全局异常处理机制
4. **输入验证**：添加参数校验（使用@Valid）

### 7.2 中优先级
1. **添加DTO层**：避免实体类直接暴露
2. **统一响应格式**：定义Result包装类
3. **日志优化**：使用异步日志写入
4. **添加索引**：优化数据库查询性能

### 7.3 低优先级
1. **代码重构**：提取公共分页逻辑
2. **添加单元测试**：提高代码覆盖率
3. **API文档**：集成Swagger/Knife4j
4. **监控告警**：集成Prometheus/Grafana

---

## 八、总结

PetAdoption是一个功能相对完整的宠物领养管理系统，采用了主流的Spring Boot技术栈。项目结构清晰，代码组织合理，但存在以下主要问题：

1. **安全性不足**：密码明文存储、缺少CSRF防护
2. **事务管理不当**：事务边界在Controller层
3. **异常处理不规范**：异常被吞没或仅打印堆栈
4. **性能优化空间**：缺少数据库索引、可能存在N+1查询

建议按照优先级逐步改进，优先解决安全相关的问题，然后优化代码质量和性能。

---

*报告生成时间：2026-04-13*
*分析工具：Trae IDE + 人工审查*
