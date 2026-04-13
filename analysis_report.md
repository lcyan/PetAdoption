# 宠物领养系统代码分析报告

## 1. 项目概述

### 1.1 项目简介
本项目是一个基于Spring Boot的宠物领养管理系统，提供宠物展示、领养申请、用户管理、管理员后台等功能。系统采用MVC架构，使用MyBatis作为ORM框架，H2内存数据库作为开发环境数据库。

### 1.2 技术栈
- **后端框架**: Spring Boot 2.3.3.RELEASE
- **模板引擎**: Thymeleaf
- **ORM框架**: MyBatis
- **数据库**: H2（开发环境）/ MySQL（生产环境）
- **构建工具**: Maven
- **容器化**: Docker
- **其他**: Druid连接池、Lombok、Bootstrap前端框架

### 1.3 项目结构
```
PetAdoption/
├── src/main/java/com/pet/demo/
│   ├── controller/     # 控制器层
│   ├── service/        # 业务逻辑层
│   ├── dao/           # 数据访问层
│   ├── entity/        # 实体类
│   ├── config/        # 配置类
│   ├── aspect/        # AOP切面
│   ├── exception/     # 异常处理
│   └── utils/         # 工具类
├── src/main/resources/
│   ├── templates/     # Thymeleaf模板
│   ├── static/        # 静态资源
│   ├── com/pet/mapper/ # MyBatis映射文件
│   ├── application.properties
│   └── schema.sql     # 数据库初始化脚本
└── Dockerfile
```

---

## 2. 关键函数/方法分析

### 2.1 登录认证流程

#### 2.1.1 验证码生成 ([LoginController.java](file:///d:/code/PetAdoption/src/main/java/com/pet/demo/controller/LoginController.java))
```java
@GetMapping("/code")
public void getCode(HttpSession session, HttpServletResponse response) {
    ValidateImageCodeUtils utils = new ValidateImageCodeUtils();
    utils.getRandCode(request, response, session);
}
```
**分析**: 使用`ValidateImageCodeUtils`工具类生成图形验证码，存储在Session中用于后续验证。

#### 2.1.2 用户登录处理
```java
@PostMapping("/login")
public String userLogin(String code, HttpSession session,
                        @RequestParam("Account") String Account,
                        @RequestParam("Password") String Password,
                        @RequestParam("role") String role,
                        Model model)
```
**分析**: 
- 验证验证码正确性
- 根据角色（管理员/用户）分别查询数据库
- 登录成功后将用户信息存入Session
- 管理员跳转到后台管理页面，普通用户跳转到首页

### 2.2 权限拦截器 ([LoginInterceptor.java](file:///d:/code/PetAdoption/src/main/java/com/pet/demo/config/LoginInterceptor.java))

```java
@Override
public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
    String Name = (String) request.getSession().getAttribute("Name");
    if (Name == null) {
        request.setAttribute("error", "没有权限请先登陆");
        request.getRequestDispatcher("/login").forward(request, response);
        return false;
    }
    return true;
}
```

**分析**:
- 通过检查Session中的"Name"属性判断用户是否登录
- 未登录用户被重定向到登录页面
- 拦截器配置在`WebConfig`中，拦截`/PetTest/**`和`/UserTest/**`路径

### 2.3 全局异常处理 ([CustomizeExceptionHandle.java](file:///d:/code/PetAdoption/src/main/java/com/pet/demo/config/CustomizeExceptionHandle.java))

```java
@ExceptionHandler(Exception.class)
ModelAndView handle(HttpServletRequest request, Throwable e, Model model,
                    HttpServletResponse response) {
    logger.error("Exception occurred: ", e);
    // 异常分类处理
}
```

**分析**:
- 使用`@ControllerAdvice`实现全局异常捕获
- 区分自定义异常和系统异常
- 对JSON请求返回JSON格式错误，对页面请求返回错误页面
- **改进**: 已添加日志记录，便于问题排查

### 2.4 AOP日志记录 ([LogAspect.java](file:///d:/code/PetAdoption/src/main/java/com/pet/demo/aspect/LogAspect.java))

```java
@Around("log()")
public Object around(ProceedingJoinPoint point) {
    // 记录请求URL、IP、类方法、参数
    // 执行目标方法
    // 记录返回结果
}
```

**分析**:
- 使用Spring AOP实现请求日志记录
- 记录请求URL、IP地址、类名方法名、请求参数和响应结果
- 有助于系统监控和问题追踪

---

## 3. 潜在风险点分析

### 3.1 安全风险

#### 3.1.1 SQL注入风险
**风险等级**: 中

**问题描述**: 部分查询方法使用字符串拼接SQL语句，存在SQL注入风险。

**示例代码** ([PetDAOMapper.xml](file:///d:/code/PetAdoption/src/main/resources/com/pet/mapper/PetDAOMapper.xml)):
```xml
<select id="findByName" resultType="com.pet.demo.entity.Pet">
    select * from t_pet where petName like '%${petName}%'
```

**改进建议**: 使用`#{}`占位符代替`${}`，MyBatis会自动进行参数转义。

#### 3.1.2 密码明文存储
**风险等级**: 高

**问题描述**: 用户密码以明文形式存储在数据库中。

**示例代码** ([UserServiceImpl.java](file:///d:/code/PetAdoption/src/main/java/com/pet/demo/service/Impl/UserServiceImpl.java)):
```java
@Override
public User login(String userAccount, String userPassword) {
    return userDao.login(userAccount, userPassword);  // 明文比较
}
```

**改进建议**: 使用BCrypt等加密算法对密码进行哈希存储。

#### 3.1.3 会话固定攻击
**风险等级**: 中

**问题描述**: 登录成功后未重新生成Session ID，存在会话固定攻击风险。

**改进建议**: 登录成功后调用`request.changeSessionId()`或`session.invalidate()`后重新创建Session。

#### 3.1.4 XSS漏洞
**风险等级**: 中

**问题描述**: 部分页面直接输出用户输入内容，未进行HTML转义。

**改进建议**: 使用Thymeleaf的`th:text`自动转义，或在输出前对特殊字符进行转义。

### 3.2 性能风险

#### 3.2.1 数据库连接池配置
**风险等级**: 低

**问题描述**: Druid连接池配置较为简单，未根据实际负载进行优化。

**当前配置**:
```properties
spring.datasource.type=com.alibaba.druid.pool.DruidDataSource
```

**改进建议**: 添加连接池参数配置，如初始连接数、最大连接数、连接超时时间等。

#### 3.2.2 缺少缓存机制
**风险等级**: 中

**问题描述**: 系统未使用任何缓存机制，频繁查询数据库。

**改进建议**: 引入Redis或Caffeine缓存，缓存热点数据如宠物列表、用户信息等。

#### 3.2.3 图片资源未优化
**风险等级**: 低

**问题描述**: 宠物图片直接存储在服务器上，未进行压缩和CDN加速。

### 3.3 逻辑缺陷

#### 3.3.1 重复查询数据库
**风险等级**: 中

**问题描述**: 登录验证时重复查询数据库。

**示例代码** ([LoginController.java](file:///d:/code/PetAdoption/src/main/java/com/pet/demo/controller/LoginController.java)):
```java
if(adminService.loading(Account,Password)==null){
    model.addAttribute("error","该用户不存在");
    return "login";
}
Admin loading = adminService.loading(Account,Password);  // 第二次查询
```

**改进建议**: 将查询结果缓存到变量中，避免重复查询。

#### 3.3.2 验证码验证逻辑问题
**风险等级**: 低

**问题描述**: 验证码验证后未立即清除，可能被重复使用。

**改进建议**: 验证成功后立即清除Session中的验证码。

#### 3.3.3 并发问题
**风险等级**: 中

**问题描述**: 领养申请处理可能存在并发问题，多个用户同时申请同一只宠物。

**改进建议**: 使用数据库乐观锁或分布式锁确保数据一致性。

### 3.4 代码质量问题

#### 3.4.1 魔法字符串
**风险等级**: 低

**问题描述**: 代码中直接使用字符串常量，如角色判断使用"管理员"、"用户"。

**改进建议**: 使用枚举类型定义角色常量。

#### 3.4.2 异常处理不完善
**风险等级**: 中

**问题描述**: 部分方法未处理可能的空指针异常。

**示例**:
```java
String sessionCode = (String) session.getAttribute("code");
if(sessionCode.equalsIgnoreCase(code)){  // 可能NPE
```

**改进建议**: 添加空值检查，或使用`Objects.equals()`进行比较。

#### 3.4.3 视图名称不规范
**风险等级**: 低

**问题描述**: 部分控制器返回的视图名称带斜杠（如`/login`），导致Thymeleaf解析失败。

**修复情况**: 已修复，将`/login`改为`login`。

---

## 4. Docker构建与测试

### 4.1 Dockerfile分析

```dockerfile
FROM maven:3.8.6-eclipse-temurin-8 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests -Dmaven.repo.local=/root/.m2/repository

FROM eclipse-temurin:8-jre
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
EXPOSE 8885
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**分析**:
- 使用多阶段构建，减小最终镜像体积
- 使用Maven官方镜像进行构建
- 使用Eclipse Temurin JRE 8作为运行环境
- 暴露8885端口

### 4.2 构建与运行命令

```bash
# 构建镜像
docker build -t pet-adoption:latest .

# 运行容器
docker run -d --rm --name pet-adoption -p 8885:8885 pet-adoption:latest

# 停止容器
docker stop pet-adoption
```

### 4.3 API测试结果

| 接口 | 方法 | 状态 | 说明 |
|------|------|------|------|
| /index | GET | ✅ 200 | 首页正常访问 |
| /show | GET | ✅ 200 | 宠物展示页面正常 |
| /login | GET | ✅ 200 | 登录页面正常 |
| /login | POST | ✅ 200 | 登录验证正常（验证码校验工作） |
| /code | GET | ✅ 200 | 验证码生成正常 |
| /PetTest/pet | GET | ✅ 302 | 未登录被正确拦截 |
| /UserTest/user | GET | ✅ 302 | 未登录被正确拦截 |

---

## 5. 修复记录

### 5.1 数据库表名不一致问题
**问题**: schema.sql中表名为`pet`、`user`等，而Mapper文件中为`t_pet`、`t_user`。

**修复**: 修改schema.sql，添加`t_`前缀。

### 5.2 H2数据库列名大小写问题
**问题**: H2数据库默认将未引用的标识符转换为大写，导致列名不匹配。

**修复**: 修改application.properties，添加参数：
```properties
spring.datasource.url=jdbc:h2:mem:petadoption;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE;DATABASE_TO_LOWER=TRUE;CASE_INSENSITIVE_IDENTIFIERS=TRUE
```

### 5.3 缺少日志记录
**问题**: 全局异常处理未记录异常堆栈。

**修复**: 在CustomizeExceptionHandle中添加SLF4J日志记录。

### 5.4 Docker镜像字体库缺失
**问题**: Alpine Linux缺少字体库，导致验证码生成失败。

**修复**: 将基础镜像从`eclipse-temurin:8-jre-alpine`改为`eclipse-temurin:8-jre`。

### 5.5 Thymeleaf模板解析错误
**问题**: 控制器返回`/login`，Thymeleaf无法解析带斜杠的视图名。

**修复**: 将`return "/login"`改为`return "login"`。

---

## 6. 总结与建议

### 6.1 项目优点
1. **架构清晰**: 采用经典MVC架构，分层明确
2. **功能完整**: 涵盖宠物展示、领养申请、用户管理、管理员后台等核心功能
3. **易于部署**: 使用Docker容器化，部署简单
4. **开发友好**: 使用H2内存数据库，开发环境无需配置MySQL

### 6.2 改进建议

#### 6.2.1 安全加固
- 实现密码加密存储（BCrypt）
- 修复SQL注入漏洞
- 添加CSRF防护
- 实现会话管理安全

#### 6.2.2 性能优化
- 引入Redis缓存
- 优化数据库查询，添加索引
- 实现分页查询
- 添加连接池参数配置

#### 6.2.3 代码质量
- 使用枚举替代魔法字符串
- 完善异常处理
- 添加单元测试和集成测试
- 使用代码规范工具（如Checkstyle）

#### 6.2.4 功能增强
- 添加宠物图片上传功能
- 实现领养申请审批流程
- 添加系统通知功能
- 实现数据统计报表

### 6.3 总体评价
该项目是一个功能完整的宠物领养系统，适合作为学习项目或小型应用。代码结构清晰，但在安全性和性能方面还有提升空间。通过实施上述改进建议，可以将系统提升到生产环境可用的水平。

---

**报告生成时间**: 2026-04-13  
**分析工具**: Docker + curl + 代码审查  
**测试环境**: Windows + Docker Desktop
