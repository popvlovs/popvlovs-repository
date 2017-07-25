# Java面试题整理

标签： Spring

---

[TOC]

---

## [Spring Framework][1]
### ([Reference Documents][2]， [帮助手册][3])
> ### 特性
>
> - Dependency Injection，**依赖注入**
> - Aspect-Oriented Programming including Spring's declarative transaction management，**AOP和说明式事务管理**
> - Spring MVC web application and RESTful web service framework，**MVC和RESTful**
> - Foundational support for JDBC, JPA, JMS
> - Much more…

### Spring Framwork架构图
![Spring Framework 运行架构][4]
## Spring 技术路径
[![Spring+Framework (1).svg-17.6kB][6]](http://naotu.baidu.com/file/7aacbfb3876eb896c354831d1e1aefc0?token=fc51ed223db671a4)
链接: [Spring-IoC](#IOC)， [Spring-AOP](#AOP)， [Spring-Transaction](#Transaction)， [Spring-MVC](#MVC)
## <span id="IOC"></span>Spring IOC
### Spring IOC基础
> 什么样的系统是松耦合的？

面向接口编程（抽象编程），通过接口将软件的各个部分分离。
但在实际的软件编写中，接口是抽象的，但实现却是具体的，创建实现的过程依然形成了耦合，这就需要IOC来消除耦合。
```java
   AInterface a = new AInterfaceImp(); // 创建实现的过程是反抽象的
```
> 什么是控制反转 IOC？

`控制` 指的是肯定是IOC/DI容器控制对象，主要是控制对象实例的创建
`反转` 是相对于正向而言的，正向指当对象A依赖资源C时，在A中主动创建C的行为（主动引入）；而反转则是指由IOC容器创建好C后，注入对象A中（被动接受）。

> [Spring实现IoC的多种方式][7]
#### 1. Xml方式
可以把IoC模式看做是工厂模式的升华，把IoC看作是一个大工厂，只不过这个大工厂里要生成的对象都是在XML文件中给出定义的，然后利用Java的“反射”编程，根据XML中给出的类名生成相应的对象。从实现来看，IoC是把以前在工厂方法里写死的对象生成代码，改变为由XML文件来定义，也就是把工厂和对象生成这两者独立分隔开来，目的就是提高灵活性和可维护性。这样一来，当外部资源发生变化时，只需要修改XML文件就可以了。
```java
// 创建IoC容器
ApplicationContext ctx=new ClassPathXmlApplicationContext("IOCBeans.xml");

// 从容器中获取对象A对应的bean
AInterface a = (AInterface)ctx.getBean("A");
```

IOCBeans.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:p="http://www.springframework.org/schema/p"
    xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans.xsd">
    <bean id="bookdao" class="com.xxx.xxx.AIntefaceImpl"></bean>
</beans>
```

#### 2. 注解方式
注解的方式依然需要从xml文件定义IoC容器，但并不直接在xml文件中描述bean，而是让IoC容器去目标路径下扫描带注解的类，作为bean进行初始化。
```xml
<context:component-scan base-package="com.xxx.xxx"
    resource-pattern="xxx/A*.class">
</context:component-scan>
```

同时还可以使用`@Autowired`和`@Resource`注解进行自动装配
```java
@Autowired
@Resource(name = "A")
// 自动装配注解除了描述成员变量外，也可以描述成员变量的setter
public void setA (AInterface a) {
    this.a = a;
}
```
#### 3. 非配置式
新增一个用于替代原xml配置文件的ApplicationCfg类，代码如下：
```java
@Configuration
@ComponentScan(basePackages="com.xxx.xxx.xxx")
public class ApplicationCfg {
    @Bean
    public User getUser(){
        return new User("成功");
    }
}
```
在使用时通过注解配置类容器`AnnotationConfigApplicationContext`进行加载
```java
// 加载注解类容器
ApplicationContext ctx=new AnnotationConfigApplicationContext(ApplicationCfg.class);

// 从容器中创建
BookService bookservice=ctx.getBean(BookService.class);
User user1=ctx.getBean("user1",User.class);
```

### [SpringIoC的4种注入方式][8]
在spring ioc中有三种依赖注入，分别是：
#### 1. 自动装配，注解
@Autowired
@Resource(name = "A")
#### 2. setter方法注入
首先在bean的内部加上所依赖接口`AInterface`的`setter`方法，并在xml文件中以`<property>`标签进行描述
```xml
<!--配置bean,配置后该类由spring管理-->  
    <bean name="springAction" class="com.bless.springdemo.action.SpringAction">  
        <!--(1)依赖注入,配置当前类中相应的属性-->  
        <property name="AInterface" ref="AInterface"></property>  
    </bean>  
<bean name="AInterface" class="com.xxx.xxx.xxx.AInterface"></bean>  
```
#### 3. 构造方法注入
这种方式的注入是指带有参数的构造函数注入，也就是说需要在构造函数中将接口`AInterface`传入。
相对的，在XML文件中就不用`<property>`的形式，而是使用`<constructor-arg>`标签，`index`属性可以区分多个类型一致的接口注入
```xml
<!--配置bean,配置后该类由spring管理-->  
<bean name="springAction" class="com.bless.springdemo.action.SpringAction">  
    <!--(2)创建构造器注入,如果主类有带参的构造方法则需添加此配置-->  
    <constructor-arg index="0" ref="springDao"></constructor-arg>  
    <constructor-arg index="1" ref="user"></constructor-arg>  
</bean>  
<bean name="springDao" class="com.bless.springdemo.dao.impl.SpringDaoImpl"></bean>  
<bean name="user" class="com.bless.springdemo.vo.User"></bean>  
```
#### 4. 工厂方法注入
```java
public class SpringAction {  
    // 待注入对象  
    private ProductA product;
    
    public void setProductA(ProductA product) {  
        this.product = product;  
    }  
} 
```
与`setter`方法注入不同的是XML文件部分
```xml
<!--配置bean,配置后该类由spring管理-->  
<bean name="springAction" class="com.bless.springdemo.action.SpringAction">  
    <!--将bean ProductA 注入 product-->  
    <property name="product" ref="ProductA"></property>  
</bean>  
  
<!--ProductA依赖工厂ProductFactory生成-->  
<bean name="ProductA" factory-bean="ProductFactory" factory-method="getInstance"></bean>

<!--ProductFactory-->  
<bean name="ProductFactory" class="com.xxx.xxx.ProductFactory"></bean>  
```
### Spring Bean的生命周期
```xml
<bean id="loginAction" class=cn.csdn.LoginAction" scope="request"/>
```
**1. singleton**
    当一个bean的作用域为singleton, 那么Spring IoC容器中只会存在一个共享的bean实例，并且所有对bean的请求，只要id与该bean定义相匹配，则只会返回bean的同一实例。
**注意**：Singleton作用域是Spring中的缺省作用域

**2. prototype**
    一个bean定义对应多个对象实例。Prototype作用域的bean会导致在每次对该bean请求（将其注入到另一个bean中，或者以程序的方式调用容器的getBean()方法）时都会创建一个新的bean实例。根据经验，对有状态的bean应该使用prototype作用域，而对无状态的bean则应该使用singleton作用域。
    
**3. request**
    在一次HTTP请求中，一个bean定义对应一个实例；即每次HTTP请求将会有各自的bean实例， 它们依据某个bean定义创建而成。该作用域仅在基于web的Spring ApplicationContext情形下有效。
    
**4. session**
    在一个HTTP Session中，一个bean定义对应一个实例。该作用域仅在基于web的Spring ApplicationContext情形下有效。针对某个HTTP Session，Spring容器会根据userPreferences bean定义创建一个全新的userPreferences bean实例， 且该userPreferences bean仅在当前HTTP Session内有效。 与request作用域一样，可以根据需要放心的更改所创建实例的内部状态，而别的HTTP Session中根据userPreferences创建的实例， 将不会看到这些特定于某个HTTP Session的状态变化。 当HTTP Session最终被废弃的时候，在该HTTP Session作用域内的bean也会被废弃掉。
    
**5. global session**
    在一个全局的HTTP Session中，一个bean定义对应一个实例。典型情况下，仅在使用portlet context的时候有效。该作用域仅在基于web的Spring ApplicationContext情形下有效。    global session作用域类似于标准的HTTP Session作用域，不过仅仅在基于portlet的web应用中才有意义。Portlet规范定义了全局Session的概念，它被所有构成某个portlet web应用的各种不同的portlet所共享。在global session作用域中定义的bean被限定于全局portlet Session的生命周期范围内。

## <span id="AOP"></span>Spring AOP
AOP（Aspect Oriented Programming），即面向切面编程，是OOP（Object Oriented Programming，面向对象编程）的补充，OOP通过封装、继承、多态等特性很好的描述了对象集合的纵向关系（层次结构），而如日志、异常处理等功能则散布在所有对象层次中，这种散布在各处的无关的代码被称为横切（Cross Cutting）

AOP技术利用一种称为"横切"的技术，剖解开封装的对象内部，并将那些影响了多个类的公共行为封装到一个可重用模块，并将其命名为"Aspect"，即切面。所谓"切面"，简单说就是那些与业务无关，却为业务模块所共同调用的逻辑或责任封装起来，便于减少系统的重复代码，降低模块之间的耦合度，并有利于未来的可操作性和可维护性。

举例来说，当3个并列的类A、B、C（不存在继承关系）中，都使用了同样的业务逻辑（如安全检查，日志输出）时，OOP是无法消除这种冗余的，而AOP可以。

POP->OOP->AOP的演进过程可以参见[AOP的演进过程][9]

> 通过AOP，能够很好的减少横向的代码冗余（冗余代码被整合为Aspect）
### AOP核心概念

**1、横切关注点**
对哪些方法进行拦截，拦截后怎么处理，这些关注点称之为横切关注点

**2、切面（aspect）**
类是对物体特征的抽象，切面就是对横切关注点的抽象

**3、连接点（joinpoint）**
被拦截到的点，因为Spring只支持方法类型的连接点，所以在Spring中连接点指的就是被拦截到的方法，实际上连接点还可以是字段或者构造器

**4、切入点（pointcut）**
对连接点进行拦截的定义

**5、通知（advice）**
所谓通知指的就是指拦截到连接点之后要执行的代码，通知分为前置、后置、异常、最终、环绕通知五类

**6、目标对象（target）**
代理的目标对象

**7、织入（weave）**
将切面应用到目标对象并导致代理对象创建的过程

**8、引入（introduction）**
在不修改代码的前提下，引入可以在运行期为类动态地添加一些方法或字段

### AOP的三种实现方式

1. 经典的基于代理的AOP，通过ProxyFactoryBean生成

2. @AspectJ注解

3. &lt;aop:config>标签

### AOP实例
#### 1. 定义Aspect类
```java
public class SecurityHandler { 
    private void checkSecurity() {  
        System.out.println("-------checkSecurity-------");  
    }         
}  
```

#### 2. 在XML中定义AOP， &lt;aop:config>
<?xml version="1.0" encoding="UTF-8"?>  
```xml
<beans  xmlns="http://www.springframework.org/schema/beans"  
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  
        xmlns:aop="http://www.springframework.org/schema/aop"  
        xmlns:tx="http://www.springframework.org/schema/tx"  
        xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans-2.0.xsd
        http://www.springframework.org/schema/aop
        http://www.springframework.org/schema/aop/spring-aop-2.0.xsd
        http://www.springframework.org/schema/tx
        http://www.springframework.org/schema/tx/spring-tx-2.0.xsd">  
    
    <!-- Target -->         
    <bean id="userManager" class="com.bjpowernode.spring.UserManagerImpl"/>  
    
    <!-- Aspect -->
    <bean id="securityHandler" class="com.bjpowernode.spring.SecurityHandler"/>  
      
    <!-- proxy-target-class="false" 则使用JDK Proxy（默认，基于接口），否则使用CGLIB（基于类） -->
    <aop:config proxy-target-class="false">
        <!-- aspect -->
        <aop:aspect id="secutityAspect" ref="securityHandler">
            <!-- pointcut -->
            <aop:pointcut id="pointcutAdd" expression="execution(* com.bjpowernode.spring.*.add*(..)) || execution(* com.bjpowernode.spring.*.del*(..))"/>
            <!-- advice，共有5种 -->
            <aop:before method="checkSecurity" pointcut-ref="pointcutAdd"/>
            <aop:after method="checkSecurity" pointcut-ref="pointcutAdd"/>
            <aop:after-returning method="checkSecurity" pointcut-ref="pointcutAdd"/>
            <aop:after-throwing method="checkSecurity" pointcut-ref="pointcutAdd"/>
            <aop:around method="checkSecurity" pointcut-ref="pointcutAdd"/>
        </aop:aspect>
    </aop:config>  
</beans>
```
当然也可以使用advisor（一个pointcut和一个advice）代替aspect（多个pointcut和多个advice），advisor是一个特殊的aspect。
```xml
 <aop:config proxy-target-class="false">
    <aop:advisor advice-ref="txAdvice1" pointcut="execution(* com.XXX..*.*Dao.*(..))" />
    <aop:advisor advice-ref="txAdvice2" pointcut="execution(* com.XXX..*.*Dao.*(..))" />
 </aop:config>  
```

#### 3. @AspectJ注解式

    @Pointcut("execution(* com.xxx.xxx.addUser(..))")
    @Before(..)
    @Around(..)
    @AfterReturning(..)
    @AfterThrowing(..)
    @After(..)

需要注意的是，采用注解式时需要在xml中开启支持
```xml
<!-- 启动@aspectj的自动代理支持-->
<aop:aspectj-autoproxy />
```
#### 4. 切入点指示符，expression
- **通配符**
`..`：匹配任意数量的（包名 | 参数）
`*`：匹配任意数量字符
`+`：匹配所有子类
- **类型签名表达式**
`within(<type name>)`，匹配目标类内的所有连接点
- **方法签名表达式**
`execution(<scope> <return-type> <fully-qualified-class-name>.*(parameters))`
```java
//匹配UserDaoImpl类中第一个参数为int类型的所有公共的方法
@Pointcut("execution(public * com.zejian.dao.UserDaoImpl.*(int , ..))")
```
- **其他指示符**
    - bean：Spring AOP扩展的，AspectJ没有对于指示符，用于匹配特定名称的Bean对象的执行方法；
    - this：用于匹配当前AOP代理对象类型的执行方法；请注意是AOP代理对象的类型匹配，这样就可能包括引入接口也类型匹配
    - target：匹配实现指定接口的目标对象
    - args：匹配具有指定形参名的方法
    - @within：匹配使用指定注解的类
    - @annotation：匹配使用指定注解的方法
    - ....
#### 5. Advisor，通知器

### AOP底层原理
Spring AOP的实现原理是基于动态织入的动态代理技术，动态代理技术分为Java JDK动态代理和CGLIB动态代理，前者是基于反射技术的实现（要求target实现了某个interface），后者是基于继承的机制实现，但依赖开源库CGLIB
![AOP动态代理原理][10]

## <span id="Transaction"></span>Spring Transaction，事务管理
> **使用Spring Transaction的优点**
>
> - 为不同的事务API提供统一的编程模式，如JTA（Java Transaction API），JDBC，Hibernate，JPA（Java Persistent API），JDO（Java Data Objects）...
> - 支持声明式的事务管理
> - 更加简单易用的API（相对于JPA之类）
> - 与Spring Data Access进行良好的整合

可以通过Bean的形式引入TransactionManager的实例（实现PlatformTransactionManager接口）
```java
public interface PlatformTransactionManager {

    TransactionStatus getTransaction(TransactionDefinition definition) throws TransactionException;

    void commit(TransactionStatus status) throws TransactionException;

    void rollback(TransactionStatus status) throws TransactionException;
}
```
1、Jdbc Transaction
```xml
<bean id="dataSource" class="org.apache.commons.dbcp.BasicDataSource" destroy-method="close">
    <property name="driverClassName" value="${jdbc.driverClassName}" />
    <property name="url" value="${jdbc.url}" />
    <property name="username" value="${jdbc.username}" />
    <property name="password" value="${jdbc.password}" />
</bean>

<bean id="txManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
    <property name="dataSource" ref="dataSource"/>
</bean>
```

2、JTA Transaction
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:jee="http://www.springframework.org/schema/jee"
    xsi:schemaLocation="
        http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans.xsd
        http://www.springframework.org/schema/jee
        http://www.springframework.org/schema/jee/spring-jee.xsd">

    <jee:jndi-lookup id="dataSource" jndi-name="jdbc/jpetstore"/>

    <bean id="txManager" class="org.springframework.transaction.jta.JtaTransactionManager" />
</beans>
```

3、Hibernation Transaction
```xml
<bean id="sessionFactory" class="org.springframework.orm.hibernate5.LocalSessionFactoryBean">
    <property name="dataSource" ref="dataSource"/>
    <property name="mappingResources">
        <list>
            <value>org/springframework/samples/petclinic/hibernate/petclinic.hbm.xml</value>
        </list>
    </property>
    <property name="hibernateProperties">
        <value>
            hibernate.dialect=${hibernate.dialect}
        </value>
    </property>
</bean>

<bean id="txManager" class="org.springframework.orm.hibernate5.HibernateTransactionManager">
    <property name="sessionFactory" ref="sessionFactory"/>
</bean>
```
## <span id="MVC"></span>Spring MVC



  [1]: http://projects.spring.io/spring-framework/
  [2]: http://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/
  [3]: https://waylau.gitbooks.io/spring-framework-4-reference/content/
  [4]: http://docs.spring.io/spring/docs/current/spring-framework-reference/htmlsingle/images/spring-overview.png
  [6]: http://static.zybuluo.com/popvlovs1989/bp6wd69qbll3si9fq2jujfgn/Spring+Framework%20%281%29.svg
  [7]: http://www.cnblogs.com/best/p/5727935.html
  [8]: http://blessht.iteye.com/blog/1162131
  [9]: https://zhuanlan.zhihu.com/p/25522841
  [10]: https://raw.githubusercontent.com/popvlovs/popvlovs-repository/master/springAopProxy.png
