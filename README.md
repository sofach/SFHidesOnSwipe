# SFHidesOnSwipe (support ios5+)
add hidesOnSwipe to view

![](https://github.com/sofach/SFHidesOnSwipe/raw/master/demo.gif)

### Installation with CocoaPods

```ruby

pod 'SFHidesOnSwipe'

```


### Usage
```objective-c
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [yourview sf_hidesOnSwipeScrollView:yourscrollview fromFrame:orignFrame toFrame:finalFrame];
}

- (void)dealloc { // 由于有监听scroll，这里必须设置滑动的scrollview为nil，从而取消监听
    [yourview sf_hidesOnSwipeScrollView:nil fromFrame:orignFrame toFrame:finalFrame];
}
```

enjoy it
