//
//  ViewController.m
//  LinkSniffer
//
//  Created by chenyusen on 15/11/13.
//  Copyright © 2015年 chenyusen. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import "AFNetworking.h"
#import <WebKit/WebKit.h>

@interface ViewController ()
@property(nonatomic, strong) NSTextView *inputTextView;
@property(nonatomic, strong) NSTextView *outputTextView;
@property(nonatomic, strong) NSButton *allCopyButton;
@property(strong, nonatomic) NSArray *linkPrefixs;

@end

@implementation ViewController


- (NSArray *)linkPrefixs {
    if (!_linkPrefixs) {
        _linkPrefixs = @[
                         @"ed2k://",
                         @"ftp://",
                         @"thunder://"
                         ];
    }
    return _linkPrefixs;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建输入框
    NSScrollView *inputScrollView = [[NSScrollView alloc] init];
    inputScrollView.borderType = NSBezelBorder;
    inputScrollView.hasVerticalScroller = YES;
    [self.view addSubview:inputScrollView];
    [inputScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(inputScrollView.superview).offset(20);
        make.left.equalTo(inputScrollView.superview).offset(20);
        make.right.equalTo(inputScrollView.superview).offset(-20);
        make.height.mas_greaterThanOrEqualTo(50);
        make.height.mas_lessThanOrEqualTo(150);
        make.width.mas_greaterThanOrEqualTo(350);
    }];
    _inputTextView = [[NSTextView alloc] init];
    _inputTextView.horizontallyResizable = YES;
    _inputTextView.verticallyResizable = YES;
    _inputTextView.editable = YES;
    _inputTextView.richText = NO;
    inputScrollView.documentView = _inputTextView;
    
    NSTextField *reminderLabel = [[NSTextField alloc] init];
    reminderLabel.backgroundColor = [NSColor clearColor];
    reminderLabel.bordered = NO;
    reminderLabel.bezeled = NO;
    reminderLabel.editable = NO;
    reminderLabel.stringValue = @"直接输入URL地址或源码";
    [self.view addSubview:reminderLabel];
    [reminderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(inputScrollView.mas_bottom).offset(10);
        make.left.equalTo(reminderLabel.superview).offset(20);
    }];
    
    // 创建按钮
    NSButton *analyzeButton = [[NSButton alloc] init];
    analyzeButton.bezelStyle = NSRoundedBezelStyle;
    analyzeButton.bordered = YES;
    analyzeButton.title = @"解析";
    analyzeButton.target = self;
    [analyzeButton setAction:@selector(analyzeButtonPressed:)];
    [self.view addSubview:analyzeButton];
    [analyzeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(inputScrollView.mas_bottom).offset(20);
        make.right.equalTo(analyzeButton.superview).offset(-20);
        make.size.mas_equalTo(CGSizeMake(80, 30));
    }];
    
    _allCopyButton = [[NSButton alloc] init];
    _allCopyButton.bezelStyle = NSRoundedBezelStyle;
    _allCopyButton.bordered = YES;
    _allCopyButton.title = @"复制全部";
    _allCopyButton.target = self;
    _allCopyButton.enabled = NO;
    [_allCopyButton setAction:@selector(allCopyButtonPressed:)];
    [self.view addSubview:_allCopyButton];
    [_allCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(analyzeButton);
        make.right.equalTo(analyzeButton.mas_left).offset(-20);
        make.size.mas_equalTo(CGSizeMake(80, 30));
    }];

    // 创建输出框
    NSScrollView *outputScrollView = [[NSScrollView alloc] init];
    outputScrollView.borderType = NSBezelBorder;
    [self.view addSubview:outputScrollView];
    [outputScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.bottom.equalTo(outputScrollView.superview).offset(-40);
        make.left.equalTo(outputScrollView.superview).offset(20);
        make.right.equalTo(outputScrollView.superview).offset(-20);
        make.top.equalTo(analyzeButton.mas_bottom).offset(20);
        make.height.mas_greaterThanOrEqualTo(150);
    }];
    
    _outputTextView = [[NSTextView alloc] init];
    _outputTextView.editable = NO;
    _outputTextView.selectable = YES;
    _outputTextView.horizontallyResizable = YES;
    _outputTextView.verticallyResizable = YES;
    _outputTextView.editable = YES;
    outputScrollView.documentView = _outputTextView;
    
    // 设置design
    NSTextField *designLabel = [[NSTextField alloc] init];
    designLabel.backgroundColor = [NSColor clearColor];
    designLabel.bordered = NO;
    designLabel.bezeled = NO;
    designLabel.editable = NO;
    designLabel.stringValue = @"Designed By TechSen";
    [self.view addSubview:designLabel];
    [designLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(outputScrollView.mas_bottom).offset(10);
        make.bottom.equalTo(designLabel.superview).offset(-10);
        make.right.equalTo(designLabel.superview).offset(-20);
    }];
    
}


- (void)analyzeButtonPressed:(NSButton *)sender {
    // 先设为不可用,直到解析完毕为止
    _allCopyButton.enabled = NO;
    
    // 准备用于解析的string
    NSString *prepareScanString = _inputTextView.string;
    
    if (prepareScanString.length > 0) {
        if ([self isCorrectUrl:prepareScanString]) { // 如果是网址
            
            [self getSourceCodeWithUrl:prepareScanString success:^(NSString *sourceCode) {
                NSString *analyzedString = [self analyzeFromString:sourceCode];
                if (analyzedString.length > 0) {
                    _outputTextView.string = [self analyzeFromString:sourceCode];
                    _allCopyButton.enabled = YES;
                } else {
                    _outputTextView.string = @"未闻到下载链接的味道(⊙_⊙)";
                    _allCopyButton.enabled = NO;
                }
            } failure:^(NSError *error) {
                _allCopyButton.enabled = NO;
                _outputTextView.string = @"艹,网页打不开啊";
            }];
        } else { // 如果是源码
            NSString *analyzedString = [self analyzeFromString:prepareScanString];
            if (analyzedString.length > 0) {
                _outputTextView.string = [self analyzeFromString:prepareScanString];
                _allCopyButton.enabled = YES;
            } else {
                _outputTextView.string = @"未闻到下载链接的味道(⊙_⊙)";
                _allCopyButton.enabled = NO;
            }
        }
    } else {
        _allCopyButton.enabled = NO;
        _outputTextView.string = @"艹,裤子都脱了,你让我看这个";
    }
}


- (void)allCopyButtonPressed:(NSButton *)sender {
    NSPasteboard *pastBoard = [NSPasteboard generalPasteboard];
    [pastBoard clearContents];
}

- (void)getSourceCodeWithUrl:(NSString *)urlString success:(void(^)(NSString *sourceCode))success failure:(void(^)(NSError *error)) failure {
    // 打开链接
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html"]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSString *responseString = [[NSString  alloc] initWithData:responseObject encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)]; // GBK解码
        if (responseString.length == 0) {
            responseString = [[NSString  alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]; // UTF-8解码
        }
        if (responseString.length == 0) {
            responseString = [[NSString alloc] initWithData:responseObject encoding:NSUnicodeStringEncoding];
        }
        success(responseString);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (NSString *)analyzeFromString:(NSString *)string {
    NSMutableString *totalString = [NSMutableString string];
    NSScanner * scanner = [NSScanner scannerWithString:string];   // 创建扫描器
    NSString *defaultPrefix = @"href=\"";
    NSString *defualtSuffix = @"\">";
    while (true) {
        NSString * scannedString;
        while (true) {
            BOOL flag = NO;
            NSString *keyString;
            for (int i = 0; i < self.linkPrefixs.count; i++) {
                [scanner scanString:[NSString stringWithFormat:@"%@%@",defaultPrefix,self.linkPrefixs[i]] intoString:&keyString]; // 遍历需要遍历的前缀
                if (keyString) {
                    NSInteger length = [self.linkPrefixs[i] length];
                    scanner.scanLocation -= length;
                    flag = YES;
                    break;
                }
            }
            if (flag) break;
            if (!keyString) { // 如果无对应前缀,直接句柄后移
                scanner.scanLocation ++;
                if ([scanner isAtEnd]) {
                    break;
                }
            }
        }
        if ([scanner isAtEnd]) {
            break;
        }
        [scanner scanUpToString:defualtSuffix intoString:&scannedString];
        [totalString appendString:[NSString stringWithFormat:@"%@\n",scannedString]];
    }
    return totalString;
}

- (BOOL)isCorrectUrl:(NSString *)urlString {
    
    NSString *regex = @"http(s)?:\\/\\/([\\w-]+\\.)+[\\w-]+(\\/[\\w- .\\/?%&=]*)?";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:urlString];
}


@end
