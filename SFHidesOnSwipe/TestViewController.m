//
//  TestViewController.m
//  SFHidesOnSwipe
//
//  Created by 陈少华 on 15/12/3.
//  Copyright © 2015年 sofach. All rights reserved.
//

#import "TestViewController.h"
#import "UIView+SFHidesOnSwipe.h"

@interface TestViewController () <UITableViewDelegate, UITableViewDataSource>

@property (assign, nonatomic) CGRect navibarOrignFrame;
@property (assign, nonatomic) CGRect tabbarOrignFrame;

@property (strong, nonatomic) UIView *topView;

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"滑动隐藏";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellid"];
    self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    [self.view addSubview:self.tableView];
    
    _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 44)];
    _topView.backgroundColor = self.navigationController.navigationBar.barTintColor;
    [self.view addSubview:_topView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self hidesOnScrollView:self.tableView];
}

- (void)dealloc { // 由于有监听scroll，这里必须设置滑动的scrollview为nil，从而取消监听
    [self hidesOnScrollView:nil];
}

- (void)hidesOnScrollView:(UIScrollView *)scrollView {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGSize navibarSize = self.navigationController.navigationBar.frame.size;
    CGSize tabbarSize = self.tabBarController.tabBar.frame.size;
    
    [_topView sf_hidesOnSwipeScrollView:scrollView fromFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 44) toFrame:CGRectMake(0, -44, [UIScreen mainScreen].bounds.size.width, 44)];
    
    [self.navigationController.navigationBar sf_hidesOnSwipeScrollView:scrollView fromFrame:CGRectMake(0, 20, navibarSize.width, navibarSize.height) toFrame:CGRectMake(0, -navibarSize.height-44, navibarSize.width, navibarSize.height)]; //为了在显示时遮住topview，多上移了44
    
    [self.tabBarController.tabBar sf_hidesOnSwipeScrollView:scrollView fromFrame:CGRectMake(0, screenSize.height-tabbarSize.height, tabbarSize.width, tabbarSize.height) toFrame:CGRectMake(0, screenSize.height, tabbarSize.width, tabbarSize.height)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellid" forIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"this is row %li", indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"logo_icon"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView reloadData];
    [self hidesOnScrollView:self.tableView];

//    [self hidesOnScrollView:self.tableView];
}

@end
