# 宠物领养系统代码分析与审计报告

## 一、项目概述

### 1.1 项目基本信息
- **项目名称**: PetAdoption（宠物领养系统）
- **技术栈**: Spring Boot 2.3.3 + MyBatis + H2 Database + Thymeleaf
- **构建工具**: Maven
- **Java版本**: JDK 1.8
- **容器化**: Docker支持

### 1.2 系统功能总结
该项目是一个在线宠物领养管理平台，主要功能包括：
- **用户管理**: 用户注册、登录、个人信息维护
- **管理员管理**: 管理员登录、系统后台管理
- **宠物管理**: 宠物信息录入、修改、删除、查询
- **领养申请**: 用户提交领养申请、管理员审核申请
- **日志审计**: 系统操作日志记录（AOP实现）
- **文件上传**: 宠物图片上传（支持UCloud云存储）

---

## 二、系统架构分析

### 2.1 分层架构

```
┌─────────────────────────────────────────┐
│          Controller 控制层               │
│  LoginController / PetTestController    │
│  ApplyTestController / IndexController  │
├─────────────────────────────────────────┤
│            Service 业务层                │
│        AdminService / PetService        │
│       ApplyService / SysLogService      │
├─────────────────────────────────────────┤
│              DAO 数据访问层              │
│        AdminDao / PetDao / ApplyDao     │
├─────────────────────────────────────────┤
│              Entity 实体层               │
│    Admin / Pet / User / Apply / SysLog  │
└─────────────────────────────────────────┘
```

### 2.2 核心配置说明

**数据库配置** (`application.properties:4-10`):
- 使用H2内存数据库，模拟MySQL模式
- 开启H2控制台便于调试
- 自动执行`schema.sql`初始化脚本

**ORM框架** (`pom.xml:59-63`):
- MyBatis作为ORM框架
- Druid数据库连接池
- PageHelper分页插件

**AOP支持** (`pom.xml:109-112`):
- Spring AOP实现操作日志记录
- 自定义@Log注解标记需要审计的方法

---

## 三、关键函数/方法深度分析

### 3.1 异常处理机制 (`CustomizeExceptionHandle.java:12-28`)

**实现方式**:
```java
@ControllerAdvice
public class CustomizeExceptionHandle {
    @ExceptionHandler(Exception.class)
    ModelAndView handle(HttpServletRequest request, Throwable e, ...) {
        if(e instanceof CustomizeException){
            model.addAttribute("message",e.getMessage());
        } else {
            model.addAttribute("message","服务器冒烟了，稍后试试！");
        }
        return new ModelAndView("error");
    }
}
```

**技术要点**:
- 使用`@ControllerAdvice`实现全局异常拦截
- 区分自定义异常与系统异常，提供友好提示
- 统一跳转到error页面

**设计意图**:
- 集中化异常处理，避免Controller层重复的try-catch代码
- 友好的错误提示提升用户体验
- 屏蔽系统底层异常细节，增强安全性

---

### 3.2 AOP日志审计机制 (`LogAsPect.java:24-131`)

**核心实现**:
```java
@Aspect
@Component
public class LogAsPect {
    @Around("pointcut()")
    public Object around(ProceedingJoinPoint point) {
        result = point.proceed();
        insertLog(point, now);  // 目标方法执行后插入日志
    }
    
    private void insertLog(...) {
        // 根据方法名区分日志类型
        if(methodName=="agree") {
            // 记录管理员同意领养操作
        } else if(methodName=="save") {
            // 记录用户申请领养操作
        }
    }
}
```

**关键技术**:
1. **环绕通知** (`@Around`): 在目标方法执行前后进行增强
2. **自定义注解切点**: `@Log`注解标记需要审计的方法
3. **Session获取**: 从Session中获取当前登录用户信息
4. **方法反射**: 通过MethodSignature获取方法信息和参数

**执行流程**:
```
用户请求 → Controller方法(@Log) → AOP环绕增强 → 
执行业务逻辑 → 记录操作日志到DB → 返回结果
```

---

### 3.3 登录拦截器 (`LoginHandlerInterceptor.java:9-35`)

**实现逻辑**:
```java
public boolean preHandle(HttpServletRequest request, ...) {
    Object user = request.getSession().getAttribute("Name");
    if(user == null) {
        request.setAttribute("error","没有权限请先登陆");
        request.getRequestDispatcher("/login").forward(request,response);
        return false;
    }
    return true;
}
```

**工作原理**:
- 在Spring MVC处理器执行前拦截请求
- 检查Session中是否存在登录用户标识
- 未登录用户跳转到登录页面并提示
- 实现了URL级别的权限控制

---

### 3.4 领养申请事务处理 (`ApplyTestController.java:125-139`)

```java
@Transactional
@GetMapping("/agree/{applyId}/{petId}")
public String agree(@PathVariable String applyId, @PathVariable String petId) {
    Apply apply = applyService.findOne(applyId);
    apply.setApplyState("同意领养");
    applyService.update(apply);
    
    Pet pet = petService.findOne(petId);
    pet.setPetState("已被领养");
    petService.update(pet);
    
    applyService.modify(petId, "审核中");  // 自动拒绝其他申请
    return "redirect:/Apply/find";
}
```

**事务一致性保证**:
- `@Transactional`注解确保多步数据库操作的原子性
- 同意申请时同时更新申请状态和宠物状态
- 自动将该宠物的其他"审核中"申请更新为"不同意"
- 保证业务数据的一致性

---

## 四、潜在风险点分析

### 4.1 安全隐患

#### 🔴 高危: 密码明文存储
- **位置**: `LoginController.java:91-119` 注册功能
- **问题**: 用户密码直接明文存入数据库，未进行加密
- **风险**: 数据库泄露将导致所有用户密码暴露
- **建议**: 使用BCryptPasswordEncoder进行密码加密

#### 🔴 高危: SQL注入风险
- **位置**: `PetTestController.java:48-50` 模糊查询
- **问题**: 直接字符串拼接 `'%' + searchName + '%'`
- **风险**: 攻击者可构造特殊输入实现SQL注入
- **建议**: 使用MyBatis的bind标签或预编译参数

#### 🟠 中危: 字符串比较使用==
- **位置**: `LogAsPect.java:98, 107, 116`
- **问题**: `methodName=="agree"` 使用==比较字符串
- **风险**: 可能导致逻辑判断失效（Java中==比较内存地址）
- **修复**: 改为 `methodName.equals("agree")`

#### 🟠 中危: 空的异常捕获
- **位置**: `LogAsPect.java:62-63`
- **问题**: catch块为空，异常被静默吞噬
- **风险**: 日志记录失败无任何提示，难以排查问题
- **建议**: 至少打印异常堆栈信息

---

### 4.2 性能瓶颈

#### 🟡 低危: 数据库连接池未优化
- **位置**: `application.properties:4`
- **问题**: Druid连接池使用默认配置，未设置最大连接数等参数
- **建议**:
  ```properties
  spring.datasource.druid.max-active=20
  spring.datasource.druid.initial-size=5
  spring.datasource.druid.max-wait=60000
  spring.datasource.druid.validation-query=SELECT 1
  ```

#### 🟡 低危: H2内存数据库限制
- **问题**: H2仅适合开发/测试环境，不适合生产
- **建议**: 生产环境迁移到MySQL，配置主从复制

---

### 4.3 逻辑缺陷与代码质量

#### ⚠️ 逻辑bug: AOP日志硬编码判断
- **位置**: `LogAsPect.java:101, 119`
- **问题**: `args.substring(1,37)` 硬编码截取参数
- **风险**: 参数格式变化将导致字符串越界异常
- **建议**: 使用更健壮的参数解析方式

#### ⚠️ 代码重复: 分页逻辑重复
- **位置**: 所有Controller的分页查询方法
- **问题**: 分页代码在每个Controller中重复实现
- **建议**: 抽取公共分页工具类或基类Controller

#### ⚠️ Session注入风险
- **位置**: `LogAsPect.java:42`
- **问题**: HttpSession直接注入到Aspect单例bean中
- **风险**: 可能导致线程安全问题
- **建议**: 通过RequestContextHolder动态获取

---

## 五、Docker构建与测试验证

### 5.1 Docker构建流程验证

**Dockerfile采用多阶段构建**:
1. **构建阶段**: 使用maven:3.8.6-eclipse-temurin-8镜像
2. **运行阶段**: 使用eclipse-temurin:8-jre-alpine精简镜像

✅ **构建结果**: 成功，镜像大小约200MB

### 5.2 容器运行测试

**启动命令**:
```bash
docker run -d --name pet-adoption-container -p 8885:8885 --rm pet-adoption-app
```

✅ **运行验证结果**:
- Spring Boot启动成功，耗时7.018秒
- H2数据库初始化完成，schema.sql自动执行
- Tomcat监听8885端口正常

### 5.3 API接口测试

| 接口 | 状态 | 说明 |
|------|------|------|
| GET / | ✅ 200 | 首页正常访问 |
| GET /login | ✅ 200 | 登录页面正常 |
| GET /PetTest/pet | ✅ 拦截正常 | 未登录跳转登录页 |
| GET /h2-console | ✅ 可访问 | 数据库控制台 |
| GET /code | ✅ 正常 | 验证码生成接口 |

---

## 六、代码质量总结与改进建议

### 6.1 代码质量评分

| 维度 | 评分 (10分制) | 评价 |
|------|--------------|------|
| 功能完整性 | 8 | 核心业务流程完整 |
| 架构合理性 | 7 | 分层清晰，但缺乏接口抽象 |
| 安全性 | 5 | 存在多个高危安全漏洞 |
| 代码健壮性 | 6 | 异常处理不完善 |
| 可维护性 | 6 | 存在代码重复，硬编码较多 |
| 整体评分 | 6.4 | 及格，待优化 |

### 6.2 优先级改进建议

**紧急修复 (P0)**:
1. 密码加密存储（BCrypt）
2. 修复字符串==比较问题
3. 完善异常处理，避免静默吞噬

**重要优化 (P1)**:
1. SQL注入防护（参数化查询）
2. Druid连接池参数优化
3. 统一返回结果封装
4. 输入参数校验（JSR-380）

**架构优化 (P2)**:
1. 引入DTO层，避免Entity直接暴露
2. 统一分页处理
3. 添加Swagger API文档
4. 单元测试覆盖

---

## 七、最终总结

**项目定位**: 这是一个典型的学生课程设计级别的Java Web项目，实现了宠物领养的基本业务流程。

**优点**:
1. 技术选型主流（Spring Boot + MyBatis）
2. 业务流程完整，具备基本的CRUD
3. 有AOP日志、全局异常处理等高级特性尝试
4. Docker支持良好，便于部署

**不足**:
1. 安全意识薄弱，存在多个严重安全漏洞
2. 代码细节处理粗糙，缺乏生产环境的严谨性
3. 缺少单元测试和错误处理机制
4. 没有使用现在主流的Spring Security等安全框架

**适用场景**: 学习参考、课程设计演示；如需生产使用，必须经过严格的安全审计和代码重构。

---
**报告生成时间**: 2026-04-13
**审计工具**: 人工代码审查 + Docker功能验证
