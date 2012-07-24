lively-logic
============
 
 
目录
---------

一、简介
---------

lively-logic 是一个游戏参数实时调节框架，所谓实时调节，也就是在游戏程序运行的过程中调节游戏的参数。在源码中提供了框架本身和一个demo。

lively-logic所使用的是racket语言，racket是一门动态语言，也是一门lisp语言，更是一门FP语言。racket的官方网站是： <http://racket-lang.org/> ，下载安装即可。racket有着非常丰富的文档，非常方便初学者学习。

二、概念
-----------

### 1、首先把游戏看做一个函数f。

这个函数的形式是：

                     state -> dt  -> events -> state
                 
其中state表示游戏某一时刻的状态，dt表示状态更新的时间间隔，events表示dt内发生的事件，一般是用户输入的鼠标时间和键盘事件。


也就是：

                         f(s,dt,e) = s'
                               
假设有初始状态s0和事件e0,调用函数f，就能获得下一个状态s1，也即：

                        f(s0,dt,e0) = s1
                                
通过f和s0和用户的输入(e0,e1,e2....)可以得到一个状态序列

                        s0 s1 s2 s3 s4....
                                
最后由观察者把这些状态表现出来。

### 2、f的特性。

一个纯粹的函数是指没有任何副作用的函数。副作用其实是指函数在其内部保存某种隐藏的状态。f是一个纯粹的函数，
也就是每次调用函数f，只要输入相同，输出一定相同。

相对于我们的游戏：

                f(s0,dt,e0) = s1                
                f(s1,dt,e1) = s2                      历史重演
                       ...                      
                f(sn,dt,en) = sn+1              f(sn,dt,en) = sn+1
                f(sn+1,dt,en) = sn+2            f(sn+1,dt,en) = sn+2
                        ...                          ...
                                                     ...           
也就是说在未来的某一时刻，可以让f重新作用于历史上的某一状态，能产生出相同的历史。这里重新作用于状态sn，从而让历史从sn处开始重演，但是历史没有改变。

### 3、时间

我们把f作用后所产生的状态称为当前，把之后将要产生的状态称为未来，之前的状态称为历史。也就是说我们的时间不只有向前流逝（让f作用于当前状态），我们可以让时间暂停（让f一直作用在当前的前一状态），或者重演历史（让f重新从历史上的某一个状态开始作用）。如果我们让f作用到历史上的某一时刻，那么这一时刻变成了当前，这一时刻之后的历史成为了未来。

向前流逝：

                s0
                s0 s1 
                s0 s1 s2
                s0 s1 s2 s3
                s0 s1 s2 s3 s4
                ...

暂停：

                s0
                s0 s1
                s0 s1
                s0 s1
                .....

重演历史：

                s0
                s0 s1
                s0 s1 s2
                s0 s1 s2 s3
                s0 s1
                s0 s1 s2
                s0 s1 s2 s3
                .....
                
### 4、改变未来

当我们在当前时刻改变f为f'，意味着未来将会改变。

![change future](https://github.com/zanezhang/lively-logic/raw/master/doc/images/changefuture.png)

### 5、 改变历史

当我们把当前时刻回到历史上某一时刻，我们能够重演历史。当我们在当前时刻改变f'，我们能够改变未来。把两者结合，我们就能够改变历史。

![change history](https://github.com/zanezhang/lively-logic/raw/master/doc/images/changehistory.png)

三、具体实现
-------------------------------

*   我们保存了历史上前一段时间的状态，所以我们能够重演历史。
*   demo是用racket写的。racket的eval函数可以在程序运行过程中可以动态编译运行代码。所以我们能够改变f，也就是能够改变未来。

重演历史+改变未来=改变历史
            
四、如何使用
--------------------------------------

### 1、源代码目录组织

源代码的目录组织如下：

.\
   
.\demo
   
.\doc
   
.\src
   
.\README.md
   
.\AUTHORS

其中demo目录下包含了一个使用此框架的游戏demo；doc目录下是此框架的文档信息；src目录下是此框架的源码。
   
### 2、demo

如果你只想看看这是一个什么东西，那么请用racket打开demo目录下的pallet-game.rkt文件，然后运行即可。

如果你想使用我们的框架，那么你也可以参考demo的代码。

### 3、快捷键

这里所指的快捷键是指当键盘输入焦点在游戏的canvas上时，用户输入的快捷键。

ctrl+p 暂停游戏。

ctrl+c 继续游戏。

ctrl+t 显示或者关闭轨迹，在游戏暂停时才有效。

### 4、滑动条

当游戏暂停时，通过拖动滑动条，可以达到历史上的某一时刻。

### 5、编辑器

编辑器内为游戏主逻辑函数的代码，可以在游戏运行过程中或者暂停时，实时改变代码，从而达到立即改变游戏逻辑的目的。

### 6、框架类

lively-logic框架通过一个类提供接口，这个类的类名为myframework%，在文件framework.rkt中定义。

    myframework% : class?
      superclass : onject%

一个myframework%对象定义了游戏运行的一种机制，只要对象初始化的时候传入适当的参数，游戏就能运，并且能够方便的调节游戏参数。

    (new myframework% [itv itv] 
                      [mainf mainf] 
                      [showf showf]
                      [drawpointf drawpointf]
                      [inits inits]
                      [copystate copystate]
                      [keyeventfilter keyeventfilter]
                      [mouseeventfilter mouseeventfilter])
    -> (is-a?/c myframework%)
      
此函数用来创建一个myframework%对象。其中itv表示游戏逻辑帧的时间间隔，也就是1/itv为逻辑帧的帧率。

mainf是一个字符串，表示游戏逻辑函数mainloop的代码所在的文件。框架运行后，文件内的代码将被求值为一个lambda表达式，作为游戏的逻辑函数。同时代码将在编辑框中显示，可在游戏运行过程中动态的修改代码。函数mainloop的形式是：

      (lambda (dt eventlist state)
        ...)
       ->state

showf是一个lambda表达式，用来向canvas绘制整个游戏。每次逻辑更新后，也即调用mainloop函数后，showf将会被调用，来显示新的一帧游戏画面。showf的形式是：

      (lambda (dc state)
        ...)
       ->any/c

drawpointf是一个lambda表达式，用来向canvas绘制游戏中某些对象的轨迹。当游戏暂停时，此函数会被调用来绘制轨迹，从而方便调节游戏参数。drawpointf的形式是：
 
      (lambda (dc state)
        ...)
       ->any/c
        
inits是游戏的初始状态，类型为用户自定义。

copystate是一个lambda表达式，用来拷贝游戏状态。用户可以通过定义这个函数来自定义游戏状态的拷贝方式。copystate的形式是：

     (lambda (state)
        ...)
      ->state

keyeventfilter是一个lambda表达式，用来过滤键盘输入事件。当lively-logic框架接收到键盘事件，且焦点在canvas上时，键盘事件通过keyeventfilter过滤后放入eventlist中，在下一次逻辑更新时使用，当keyeventfilter返回#f时，表示这个事件被抛弃。keyeventfilter的形式是:

     (lambda (event)
        ...)
     ->(or/c (any/c) (#f))

mouseeventfilter是一个lambda表达式，用来过滤鼠标输入事件。当lively-logic框架的canvas接收到鼠标事件时，鼠标事件通过mouseeventfilter过滤后放入eventlist中，在下一次逻辑更新时使用，当mouseeventfilter返回#f时，表示这个事件被抛弃。mouseeventfilter的形式是:

     (lambda (event)
        ...)
     ->(or/c (any/c) (#f))
     
下面是这个类所提供的接口：

     (send a-framework run) -> any/c

此函数用来启动框架。
      
      (send a-framework recaculate) -> any/c
     
此函数强迫框架重新计算。

