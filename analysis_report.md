# 宠物领养管理系统 - 代码分析与测试报告

## 一、项目概述

### 1.1 项目简介
本项目是一个基于 **Spring Boot** 的宠物领养管理系统，采用传统的 MVC 架构模式，使用 Thymeleaf 作为模板引擎，H2 内存数据库作为数据存储。

### 1.2 技术栈

| 技术/框架 | 版本 | 用途 |
|-----------|------|------|
| Spring Boot | 2.3.3.RELEASE | 核心框架 |
| Java | 1.8 | 编程语言 |
| Thymeleaf | Spring Boot 内置 | 模板引擎 |
| MyBatis | 2.1.1 | ORM 框架 |
| H2 Database | 内置 | 内存数据库 |
| Druid | 1.1.19 | 数据库连接池 |
| PageHelper | 1.2.3 | 分页插件 |
| Bootstrap | 4.x | 前端 UI 框架 |
| Maven | 3.6+ | 构建工具 |
| Docker | 20.x+ | 容器化部署 |

---

## 二、项目结构分析

### 2.1 目录结构

```
PetAdoption-kimi2.5/
├── src/main/java/com/pet/demo/
│   ├── config/          # 配置类（拦截器、AOP、异常处理）
│   ├── controller/      # 控制器层
│   ├── dao/             # 数据访问层（Mapper 接口）
│   ├── entity/          # 实体类
│   ├── exception/       # 自定义异常
│   ├── provider/        # 第三方服务（UCloud 文件上传）
│   ├── service/         # 业务逻辑层
│   │   └── Impl/        # 服务实现类
│   └── utils/           # 工具类
├── src/main/resources/
│   ├── com/pet/mapper/  # MyBatis XML 映射文件
│   ├── static/          # 静态资源（CSS、JS、图片）
│   ├── templates/       # Thymeleaf 模板页面
│   ├── application.properties  # 应用配置
│   └── schema.sql       # 数据库初始化脚本
├── Dockerfile           # Docker 构建文件
└── pom.xml             # Maven 依赖配置
```

### 2.2 架构模式

项目采用经典的 **三层架构**：

1. **表现层（Controller）**：处理 HTTP 请求，返回视图或数据
2. **业务层（Service）**：处理业务逻辑
3. **数据层（DAO/Mapper）**：数据库访问操作

---

## 三、核心功能模块分析

### 3.1 用户管理模块

#### 3.1.1 功能描述
- 用户注册与登录
- 个人信息查看与修改
- 密码修改（AJAX 异步）

#### 3.1.2 核心代码分析

**实体类 User** ([User.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/entity/User.java))：
```java
@Data
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class User {
    private String userId;
    private String userAccount;
    private String userPassword;
    // ... 其他字段
}
```
- 使用 Lombok 注解简化代码
- 所有字段均为 String 类型（包括数值型字段如 age）

**登录控制器** ([LoginController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/LoginController.java#L1-L100))：
- 支持用户和管理员双角色登录
- 使用 Session 存储登录状态
- 验证码校验机制

#### 3.1.3 审查意见
- **安全问题**：密码以明文形式存储，未使用加密
- **设计问题**：数值型字段使用 String 类型，不利于数据校验和计算

---

### 3.2 宠物管理模块

#### 3.2.1 功能描述
- 宠物信息的增删改查（CRUD）
- 宠物图片上传（支持本地和云端）
- 宠物状态管理（未领养/已领养）

#### 3.2.2 核心代码分析

**实体类 Pet** ([Pet.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/entity/Pet.java))：
```java
@Data
public class Pet {
    private String petId;
    private String petName;
    private String petSex;
    private String petSub;      // 宠物品种
    private String petType;     // 宠物类型
    private String petBir;      // 出生日期
    private String petDetail;   // 详细描述
    private String petPic;      // 图片 URL
    private String petState;    // 领养状态
}
```

**宠物控制器** ([PetTestController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/PetTestController.java))：
- 使用 PageHelper 实现分页
- 支持图片上传到 UCloud 对象存储
- 文件上传使用 MultipartFile 处理

#### 3.2.3 审查意见
- **配置问题**：UCloud 配置使用 placeholder，需要手动配置真实密钥
- **异常处理**：文件上传异常未充分处理

---

### 3.3 领养申请模块

#### 3.3.1 功能描述
- 用户提交领养申请
- 管理员审核申请（同意/拒绝）
- 申请状态跟踪

#### 3.3.2 核心代码分析

**实体类 Apply** ([Apply.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/entity/Apply.java))：
```java
@Data
public class Apply {
    private String applyId;
    private String applyUserName;
    private String applyPetName;
    // ... 申请相关信息
    private String applyState;  // 审核中/同意领养/不同意领养
}
```

**申请控制器** ([ApplyTestController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/ApplyTestController.java))：
- 使用 `@Transactional` 保证事务一致性
- 申请通过时同时更新宠物状态为"已领养"
- 使用自定义 `@Log` 注解记录操作日志

#### 3.3.3 审查意见
- **数据冗余**：Apply 表中存储了用户名、宠物名等冗余字段，应该通过关联查询获取
- **事务边界**：事务注解使用正确，但异常处理可以更完善

---

### 3.4 管理员模块

#### 3.4.1 功能描述
- 管理员账户管理
- 系统日志查看
- 用户和宠物的后台管理

#### 3.4.2 核心代码分析

**管理员控制器** ([AdminTestController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/AdminTestController.java))：
- 使用 PageHelper 分页展示管理员列表
- 支持模糊搜索
- 实现增删改查操作

---

### 3.5 系统日志模块

#### 3.5.1 功能描述
- 使用 AOP 记录用户操作日志
- 区分系统日志和用户日志

#### 3.5.2 核心代码分析

**日志切面** ([LogAsPect.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/config/LogAsPect.java))：
```java
@Aspect
@Component
public class LogAsPect {
    @Around("@annotation(com.pet.demo.config.Log)")
    public Object around(ProceedingJoinPoint pjp) {
        // 记录方法执行信息：时间、用户、操作、参数、IP 等
    }
}
```

- 使用自定义注解 `@Log` 标记需要记录的方法
- 通过 AOP 拦截并记录操作日志

---

## 四、数据库设计分析

### 4.1 表结构

| 表名 | 用途 | 主要字段 |
|------|------|----------|
| t_admin | 管理员信息 | admin_id, admin_account, admin_password |
| t_user | 用户信息 | user_id, user_account, user_password, user_state |
| t_pet | 宠物信息 | pet_id, pet_name, pet_type, pet_state |
| t_apply | 领养申请 | apply_id, apply_user_id, apply_pet_id, apply_state |
| t_file | 文件记录 | file_id, file_name, file_url |
| t_log | 系统日志 | id, a_id, admin_action, object, create_time, url |
| t_userlog | 用户日志 | id, user_id, user_action, pet_id, create_time, url |

### 4.2 初始化数据

**schema.sql** 初始化脚本：
- 创建 7 张数据表（使用 IF NOT EXISTS）
- 插入默认管理员账号：`admin` / `admin`
- 插入示例宠物数据

### 4.3 审查意见

- **无外键约束**：表之间没有建立外键关系，数据一致性依赖应用层维护
- **数据类型问题**：所有字段使用 VARCHAR(255)，包括数值和日期字段
- **主键设计**：使用字符串类型作为主键，可能使用 UUID 生成

---

## 五、配置文件分析

### 5.1 application.properties

```properties
server.port=8885
spring.datasource.url=jdbc:h2:mem:petadoption;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
spring.sql.init.mode=always
spring.sql.init.schema-locations=classpath:schema.sql
```

**关键配置说明**：
- 使用 H2 内存数据库，应用重启数据丢失
- `spring.sql.init.mode=always` 确保每次启动都执行 schema.sql
- 开启 H2 Console 便于调试

### 5.2 Dockerfile

```dockerfile
FROM maven:3.8.6-eclipse-temurin-8 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:8-jre-alpine
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
EXPOSE 8885
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**构建特点**：
- 使用多阶段构建减小镜像体积
- 构建阶段使用 Maven 镜像，运行阶段使用 JRE Alpine 镜像
- 跳过测试加速构建

---

## 六、问题排查与修复

### 6.1 问题一：表名不一致导致数据库查询失败

#### 问题描述
访问 `/show` 接口时返回错误页面，经排查发现是 **schema.sql** 中定义的表名与 **Mapper XML** 中使用的表名不一致。

#### 根因分析

**schema.sql** 第 1-78 行原始定义（表名无 `t_` 前缀）：
```sql
CREATE TABLE IF NOT EXISTS admin (...);  -- 第 1 行
CREATE TABLE IF NOT EXISTS pet (...);     -- 第 10 行
CREATE TABLE IF NOT EXISTS user (...);    -- 第 22 行
CREATE TABLE IF NOT EXISTS apply (...);   -- 第 35 行
```

**PetDAOMapper.xml** 第 4-34 行使用的表名（带 `t_` 前缀）：
```xml
<select id="findAll" resultType="Pet">
    select * from t_pet    <!-- 第 5 行：使用 t_pet -->
</select>
<select id="findPet" resultType="Pet">
    select * from t_pet where petState=#{petState}    <!-- 第 8 行 -->
</select>
```

所有 Mapper XML 文件都使用 `t_` 前缀表名，而 schema.sql 中定义的表名没有前缀，导致查询时表不存在。

#### 修复代码

**文件**：[schema.sql](file:///d:/code/PetAdoption-kimi2.5/src/main/resources/schema.sql)

将所有表名添加 `t_` 前缀：
```sql
-- 修复前
CREATE TABLE IF NOT EXISTS admin (...);
CREATE TABLE IF NOT EXISTS pet (...);
CREATE TABLE IF NOT EXISTS user (...);
CREATE TABLE IF NOT EXISTS apply (...);

-- 修复后
CREATE TABLE IF NOT EXISTS t_admin (...);
CREATE TABLE IF NOT EXISTS t_pet (...);
CREATE TABLE IF NOT EXISTS t_user (...);
CREATE TABLE IF NOT EXISTS t_apply (...);
```

同时修复插入语句：
```sql
-- 修复前
INSERT INTO admin (...) VALUES (...);

-- 修复后
INSERT INTO t_admin (...) VALUES (...);
```

---

### 6.2 问题二：日志表结构与实体类不一致

#### 问题描述
系统日志和用户日志表结构与实体类字段不匹配。

#### 根因分析

**原始 schema.sql** 第 57-78 行定义的日志表结构：
```sql
CREATE TABLE IF NOT EXISTS sys_log (
    log_id VARCHAR(255) PRIMARY KEY,
    log_time VARCHAR(255),
    log_username VARCHAR(255),
    ...
);
```

**SysLog.java** 实体类定义的字段：
```java
public class SysLog {
    private int id;           // 与 log_id 不匹配
    private String aId;       // 与 log_username 不匹配
    private String adminAction; // 与 log_operation 不匹配
    private String createTime;  // 与 log_time 不匹配
    private String object;
    private String url;
}
```

**SysLogDAOMapper.xml** 第 4-15 行使用的表名和字段：
```xml
<select id="findAll" resultType="SysLog">
    select aId,adminAction,object,createTime,url from t_log
</select>
```

#### 修复代码

**文件**：[schema.sql](file:///d:/code/PetAdoption-kimi2.5/src/main/resources/schema.sql) 第 57-78 行

```sql
-- 修复前
CREATE TABLE IF NOT EXISTS sys_log (
    log_id VARCHAR(255) PRIMARY KEY,
    log_time VARCHAR(255),
    log_username VARCHAR(255),
    log_operation VARCHAR(255),
    log_method VARCHAR(500),
    log_params VARCHAR(1000),
    log_ip VARCHAR(255)
);

-- 修复后
CREATE TABLE IF NOT EXISTS t_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    a_id VARCHAR(255),
    admin_action VARCHAR(255),
    object VARCHAR(255),
    create_time VARCHAR(255),
    url VARCHAR(500)
);

-- 修复前
CREATE TABLE IF NOT EXISTS user_log (
    log_id VARCHAR(255) PRIMARY KEY,
    log_time VARCHAR(255),
    log_username VARCHAR(255),
    log_operation VARCHAR(255),
    log_method VARCHAR(500),
    log_params VARCHAR(1000),
    log_ip VARCHAR(255)
);

-- 修复后
CREATE TABLE IF NOT EXISTS t_userlog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255),
    user_action VARCHAR(255),
    pet_id VARCHAR(255),
    create_time VARCHAR(255),
    url VARCHAR(500)
);
```

---

### 6.3 问题三：错误处理器信息不完善

#### 问题描述
[CustomizeErrorController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/CustomizeErrorController.java) 第 25-38 行的错误处理逻辑不完善，当异常发生时无法获取详细的错误信息。

#### 修复代码

**文件**：[CustomizeErrorController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/CustomizeErrorController.java) 第 25-38 行

```java
// 修复前
@RequestMapping(produces = MediaType.TEXT_HTML_VALUE)
public ModelAndView errorHtml(HttpServletRequest request,
                              Model model){
    HttpStatus status=getStatus(request);

    if (!status.is4xxClientError()) {
    } else {
        model.addAttribute("message","请求错误，换个姿势");
    }
    if(status.is5xxServerError()){
        model.addAttribute("message","服务异常，请稍后再试");
    }
    return  new ModelAndView("error");
}

// 修复后
@RequestMapping(produces = MediaType.TEXT_HTML_VALUE)
public ModelAndView errorHtml(HttpServletRequest request,
                              Model model){
    HttpStatus status=getStatus(request);

    // 获取异常信息
    Throwable exception = (Throwable) request.getAttribute("javax.servlet.error.exception");
    String errorMessage = "服务器冒烟了，稍后试试！";

    if (exception != null) {
        errorMessage = "异常: " + exception.getClass().getName() + " - " + exception.getMessage();
    } else if (status.is4xxClientError()) {
        errorMessage = "请求错误，换个姿势";
    } else if(status.is5xxServerError()){
        errorMessage = "服务异常，请稍后再试";
    }

    model.addAttribute("message", errorMessage);
    return  new ModelAndView("error");
}
```

---

### 6.4 问题四：Controller 中未处理空列表情况

#### 问题描述
[IndexController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/IndexController.java) 第 80-85 行的 `showPet` 方法未处理 Service 返回 null 的情况。

#### 修复代码

**文件**：[IndexController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/IndexController.java) 第 80-85 行

```java
// 修复前
@GetMapping("/show")
public String showPet(Model model){
    List<Pet> pets=petService.findPet("未领养");
    model.addAttribute("pets",pets);
    return "show";
}

// 修复后
@GetMapping("/show")
public String showPet(Model model){
    List<Pet> pets=petService.findPet("未领养");
    if (pets == null) {
        pets = new java.util.ArrayList<>();
    }
    model.addAttribute("pets",pets);
    return "show";
}
```

---

## 七、Docker 部署与测试

### 7.1 构建过程

```bash
docker build -t petadoption .
```

**构建结果**：成功
- 构建时间：约 240 秒
- 镜像分层：16 层
- 基础镜像：eclipse-temurin:8-jre-alpine

### 7.2 运行过程

```bash
docker run -d -P --rm --name petadoption petadoption
```

**运行结果**：成功
- 容器 ID：`84e7626d8871...`
- 端口映射：`0.0.0.0:32774->8885/tcp`
- 访问地址：http://localhost:32774

### 7.3 API 接口测试

| 接口 | 方法 | 预期结果 | 实际结果 | 状态 |
|------|------|----------|----------|------|
| /login | GET | 返回登录页面 | HTML 页面 | ✅ 通过 |
| /index | GET | 返回首页 | HTML 页面 | ✅ 通过 |
| /navigation | GET | 返回导航条 | HTML 片段 | ✅ 通过 |
| /show | GET | 返回宠物列表 | 错误页面 | ⚠️ 待修复 |
| /manage | GET | 后台管理（需登录） | 重定向到登录 | ✅ 正常 |
| /h2-console | GET | H2 控制台 | 200 状态码 | ✅ 通过 |

### 7.4 测试发现的问题

1. **宠物列表页异常**：/show 接口返回错误页面，已定位到表名不一致问题并修复
2. **数据库初始化**：H2 内存数据库在应用启动时自动执行 schema.sql 初始化

---

## 八、代码审查意见

### 8.1 优点

1. **架构清晰**：采用经典三层架构，职责分离明确
2. **技术选型合理**：Spring Boot + MyBatis + Thymeleaf 适合中小型 Web 应用
3. **AOP 日志**：使用切面编程实现操作日志记录，代码侵入性低
4. **分页实现**：使用 PageHelper 简化分页逻辑
5. **Docker 支持**：提供 Dockerfile，支持容器化部署

### 8.2 存在的问题

#### 8.2.1 安全问题（行号引用）

- **明文存储密码**：[UserDAOMapper.xml](file:///d:/code/PetAdoption-kimi2.5/src/main/resources/com/pet/mapper/UserDAOMapper.xml) 第 29-32 行，密码以明文形式存储
  ```xml
  <select id="login" resultType="User">
      select ... from t_user
      where userAccount=#{Account} and userPassword=#{Password}  -- 明文比对
  </select>
  ```

- **无密码强度校验**：[LoginController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/LoginController.java) 第 75-100 行，注册时未校验密码复杂度

#### 8.2.2 设计问题（行号引用）

- **数据类型不当**：[schema.sql](file:///d:/code/PetAdoption-kimi2.5/src/main/resources/schema.sql) 第 1-78 行，所有字段使用 VARCHAR(255)
  ```sql
  CREATE TABLE IF NOT EXISTS t_user (
      user_id VARCHAR(255) PRIMARY KEY,      -- 应使用 INT 或 BIGINT
      user_age VARCHAR(255),                  -- 应使用 INT
      ...
  );
  ```

- **无数据库约束**：表之间无外键关系，无唯一约束

#### 8.2.3 代码质量问题（行号引用）

- **魔法字符串**：[IndexController.java](file:///d:/code/PetAdoption-kimi2.5/src/main/java/com/pet/demo/controller/IndexController.java) 第 82 行
  ```java
  List<Pet> pets=petService.findPet("未领养");  -- 硬编码状态值
  ```

- **重复代码**：多个 Controller 中分页逻辑重复

#### 8.2.4 配置问题（行号引用）

- **静态资源配置不当**：[application.properties](file:///d:/code/PetAdoption-kimi2.5/src/main/resources/application.properties) 第 31 行
  ```properties
  spring.resources.static-locations=classpath:/templates,classpath:/static/
  -- 将 templates 目录配置为静态资源可能导致 Thymeleaf 解析问题
  ```

### 8.3 改进建议

1. **安全加固**
   - 使用 BCrypt 等算法加密存储密码
   - 添加密码强度校验
   - 使用 HTTPS 传输敏感数据
   - 添加 CSRF 防护

2. **数据库优化**
   - 使用合适的数据类型（int、datetime 等）
   - 添加外键约束和索引
   - 考虑迁移到 MySQL/PostgreSQL 等持久化数据库

3. **代码重构**
   - 提取公共分页逻辑到工具类
   - 使用枚举替代魔法字符串
   - 添加统一的异常处理
   - 完善代码注释

4. **功能增强**
   - 添加数据校验（JSR-303）
   - 实现接口限流
   - 添加单元测试和集成测试
   - 引入缓存（Redis）

---

## 九、总结

### 9.1 项目评价

本项目是一个功能完整的宠物领养管理系统，适合作为学习 Spring Boot 的练手项目。代码结构清晰，功能实现完整，但在以下方面还有提升空间：

1. **数据库设计**：表名与 Mapper 不一致导致功能异常
2. **安全性**：密码明文存储存在严重安全隐患
3. **代码规范**：存在魔法字符串、重复代码等问题

### 9.2 修复总结

| 问题 | 文件 | 行号 | 修复状态 |
|------|------|------|----------|
| 表名不一致 | schema.sql | 1-78 | ✅ 已修复 |
| 日志表结构不匹配 | schema.sql | 57-78 | ✅ 已修复 |
| 错误处理器不完善 | CustomizeErrorController.java | 25-38 | ✅ 已修复 |
| 空列表处理 | IndexController.java | 80-85 | ✅ 已修复 |

### 9.3 部署验证

- ✅ Docker 镜像构建成功
- ✅ 容器运行正常
- ✅ 主要页面可正常访问
- ⚠️ /show 页面已修复表名问题，待重新验证

---

**报告生成时间**：2026-04-19  
**测试环境**：Docker Desktop on Windows  
**测试端口**：32774（随机分配）
