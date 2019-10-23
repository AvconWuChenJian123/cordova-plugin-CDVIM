//
//  CDVIMFun.m
//  移动平台门户客户端
//
//  Created by wuchenjian on 2019/8/8.
//

#import "CDVIMFun.h"
#import "AFNetworking.h"
#import <WebKit/WebKit.h>
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "WFCConfig.h"
#import "GTMBase64.h"

@interface CDVIMFun()

@property (nonatomic, strong)NSMutableArray<WFCCConversationInfo *> *conversations;
@property (nonatomic, assign) BOOL firstAppear;
@property (nonatomic, assign) BOOL popVC;
@property (nonatomic, assign) BOOL groupRefresh;
@property (nonatomic, assign) NSInteger logined;
@property(nonatomic,strong)CDVInvokedUrlCommand * addConvCommand;
@property(nonatomic,strong)CDVInvokedUrlCommand * addGroupConvCommand;
@property(nonatomic,strong) NSMutableArray* messageArray;
@property(nonatomic,strong) NSMutableArray * groupListParamArray;
@property(nonatomic,strong) NSMutableArray <WFCCGroupInfo *>* groupListArray;

@end
@implementation CDVIMFun

-(NSMutableArray*)messageArray{
    if (_messageArray==nil) {
        _messageArray = [NSMutableArray array];
    }
    return _messageArray;
}

-(NSMutableArray*)groupListArray{
    if (_groupListArray==nil) {
        _groupListArray = [NSMutableArray array];
    }
    return _groupListArray;
}

-(NSMutableArray*)groupListParamArray{
    if (_groupListParamArray==nil) {
        _groupListParamArray = [NSMutableArray array];
    }
    return _groupListParamArray;
}

- (void)pluginInitialize{
    self.conversations = [[NSMutableArray alloc] init];
    self.firstAppear = YES;
    self.popVC = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutStatus:) name:kConnectionStatusLogoutNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClearAllUnread:) name:@"kTabBarClearBadgeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSendingMessageStatusUpdated:) name:kSendingMessageStatusUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didViewWillAppear:) name:CDVViewWillAppearNotification object:nil];
    
}

-(void)listenMessage{
    if (self.firstAppear) {
        self.firstAppear = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnectionStatusChanged:) name:kConnectionStatusChanged object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessages:) name:kRecallMessages object:nil];
    }
    
    [self updateConnectionStatus:[WFCCNetworkService sharedInstance].currentConnectionStatus];
    [self refreshList];
}
- (void)updateConnectionStatus:(ConnectionStatus)status{
    NSString *title;
    if (status != kConnectionStatusConnecting && status != kConnectionStatusReceiving) {

        switch (status) {
            case kConnectionStatusLogout:
            case kConnectionStatusTokenIncorrect:
               title = @"未登录";
                break;
            case kConnectionStatusUnconnected:
               title = @"未连接";
                break;
            case kConnectionStatusConnected:
               title = @"消息";
                if (self.logined) {
                    [self refreshList];
                }
                break;
            default:
                break;
        }

    } else {
        if (status == kConnectionStatusConnecting) {
            title = @"连接中...";
        } else {
            title = @"接收中...";
        }
    }
    NSString *jsStr = [NSString stringWithFormat:@"connectStatusRefresh('%@');",title];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [(WKWebView *)self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable data, NSError * _Nullable error) {
//            if (error) {
//                NSLog(@"错误:%@", error.localizedDescription);
//            }
//        }];
        [(UIWebView*)self.webView  stringByEvaluatingJavaScriptFromString:jsStr];
    });
}

- (void)onConnectionStatusChanged:(NSNotification *)notification {
    ConnectionStatus status = [notification.object intValue];
    [self updateConnectionStatus:status];
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    if ([messages count]) {
        self.popVC =YES;
        [self refreshList];
    }
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
   self.popVC =YES;
    [self refreshList];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    self.popVC =YES;
    [self refreshList];
}

- (void)onSendingMessageStatusUpdated:(NSNotification *)notification {
    self.popVC =YES;
    [self refreshList];
}

-(void)didViewWillAppear:(NSNotification *)notification{
     self.popVC = YES;
     [self refreshList];
}

- (void)onRecallMessages:(NSNotification *)notification{
    self.popVC =YES;
    [self refreshList];
}

- (void)refreshList {
    self.conversations = [[[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]] mutableCopy];
    
    [self.messageArray removeAllObjects];
    for (int i=0; i<self.conversations.count; i++) {
        WFCCConversationInfo *conv = self.conversations[i];
        NSString *targetName = @"";
        NSString *imageStr = @"";
        if (conv.conversation.type == Group_Type) {
            WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:conv.conversation.target refresh:NO];
            if(groupInfo.target.length == 0) {
                groupInfo = [[WFCCGroupInfo alloc] init];
                groupInfo.target = conv.conversation.target;
            }
            if(groupInfo.name.length > 0) {
                targetName = groupInfo.name;
            } else {
               targetName = [NSString stringWithFormat:@"group<%@>", conv.conversation.target];
            }
            if (groupInfo.portrait.length > 0) {
                imageStr = groupInfo.portrait;
            }
        }else{
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:conv.conversation.target refresh:NO];
            if(userInfo.userId.length == 0) {
                userInfo = [[WFCCUserInfo alloc] init];
                userInfo.userId = conv.conversation.target;
            }
            if (userInfo.friendAlias.length > 0) {
                targetName = userInfo.friendAlias;
            } else if(userInfo.displayName.length > 0) {
                targetName = userInfo.displayName;
            } else {
                targetName = [NSString stringWithFormat:@"user<%@>",conv.conversation.target];
            }
            if (userInfo.portrait.length > 0) {
                 imageStr = userInfo.portrait;
            }
        }
        int count=0;
        if(!conv.isSilent){
            count = conv.unreadCount.unread;
        }
        NSString *countStr = [NSString stringWithFormat:@"%d",count];
        NSString *lastMessage =  [conv.lastMessage.digest stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        NSString *lastMessageStr = [lastMessage stringByReplacingOccurrencesOfString:@"：" withString:@""];
        lastMessageStr =[lastMessageStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(lastMessageStr==nil){
            lastMessageStr = @"";
        }
        NSDictionary *messageInfo = @{@"time":[Utility formatTimeLabel:conv.timestamp],
                                      @"lastMessage":lastMessageStr,
                                      @"target":targetName,
                                      @"unread":countStr,
                                      @"headImage":imageStr,
                                      @"type":[NSNumber numberWithInteger:conv.conversation.type]
                                      };
        [self.messageArray addObject:messageInfo];
    }
    NSString *jsonResult;
    if (self.messageArray.count>0) {
        jsonResult = [Utility dictionaryToJson:self.messageArray];
    }else{
        jsonResult = @"[]";
    }
//        WKWebView *webview = (WKWebView *)self.webView;
    if (self.popVC&&!self.logined) {
        NSString *jsStr = [NSString stringWithFormat:@"ysToVue('%@');",jsonResult];
//            [webview evaluateJavaScript:jsStr completionHandler:^(id _Nullable data, NSError * _Nullable error) {
//                if (error) {
//                    NSLog(@"错误:%@", error.localizedDescription);
//                }
//            }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UIWebView*)self.webView  stringByEvaluatingJavaScriptFromString:jsStr];
        });
    }else{
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonResult];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.addConvCommand.callbackId];
    }
    
}

- (void)onClearAllUnread:(NSNotification *)notification {
    if ([notification.object intValue] == 0) {
        [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
        self.popVC =YES;
        [self refreshList];
    }
}

-(void)logoutStatus:(NSNotification*)notification{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
    [[WFCCNetworkService sharedInstance] disconnect:YES];
    self.popVC =NO;
}

-(void)enterMessageVC:(CDVInvokedUrlCommand*)command{
     __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        NSInteger  index = [[command argumentAtIndex:0] integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
            WFCCConversationInfo *info = weakSelf.conversations[index];
            mvc.conversation = info.conversation;
            [weakSelf.viewController.navigationController pushViewController:mvc animated:YES];
        });
    }];
}

-(void)refreshUnreadCount:(CDVInvokedUrlCommand*)command{
    __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        NSInteger  index = [[command argumentAtIndex:0] integerValue];
        WFCCConversationInfo *info = weakSelf.conversations[index];
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:info.conversation];
    }];
}

-(void)sendMessageVC:(CDVInvokedUrlCommand*)command{
    NSString *userId = [command argumentAtIndex:0];
    if (userId) {
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
           mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:userId line:0];
           for (UIViewController *vc in  self.viewController.navigationController.viewControllers) {
               if ([vc isKindOfClass:[WFCUMessageListViewController class]]) {
                   WFCUMessageListViewController *old = (WFCUMessageListViewController*)vc;
                   if (old.conversation.type == Single_Type && [old.conversation.target isEqualToString:userId]) {
                       [self.viewController.navigationController popToViewController:vc animated:YES];
                       return;
                   }
               }
           }
           UINavigationController *nav = self.viewController.navigationController;
           [self.viewController.navigationController popToRootViewControllerAnimated:NO];
           [nav pushViewController:mvc animated:YES];
    }
}

-(void)addFriendVC:(CDVInvokedUrlCommand*)command{
    UIViewController *addFriendVC = [[WFCUFriendRequestViewController alloc] init];
    [self.viewController.navigationController pushViewController:addFriendVC animated:YES];
}

-(void)deleteMessage:(CDVInvokedUrlCommand*)command{
     __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
         NSInteger  index = [[command argumentAtIndex:0] integerValue];
        if(index < weakSelf.conversations.count){
            [[WFCCIMService sharedWFCIMService] clearUnreadStatus:weakSelf.conversations[index].conversation];
            [[WFCCIMService sharedWFCIMService] removeConversation:weakSelf.conversations[index].conversation clearMessage:YES];
            self.popVC = YES;
            [weakSelf refreshList];
        }
    }];
}

-(void)createGroupVC:(CDVInvokedUrlCommand*)command{
    ConnectionStatus status = [WFCCNetworkService sharedInstance].currentConnectionStatus;
    if (status == kConnectionStatusRejected || status == kConnectionStatusTokenIncorrect || status == kConnectionStatusSecretKeyMismatch) {
          [self.viewController.view makeToast:@"已断开连接,请重连" duration:2 position:CSToastPositionCenter];
        return;
    }
     __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        NSString *imIdString = [command argumentAtIndex:0];
        NSData *jsonData = [imIdString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSArray *array = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
        if (array.count) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
//                dispatch_block_t invoke = ^(void) {
                   __block  WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
                    pvc.selectContact = YES;
                    pvc.multiSelect = YES;
                    pvc.showCreateChannel = NO;
                    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
                        if (contacts.count == 1) {
                            WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                            mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:contacts[0] line:0];
                            [weakSelf.viewController.navigationController pushViewController:mvc animated:YES];
                        } else {
                            WFCUCreateGroupViewController *vc = [[WFCUCreateGroupViewController alloc] init];
                            vc.memberIds = [contacts mutableCopy];
                            if (![vc.memberIds containsObject:[WFCCNetworkService sharedInstance].userId]) {
                                [vc.memberIds insertObject:[WFCCNetworkService sharedInstance].userId atIndex:0];
                            }
                            [strongSelf.viewController.navigationController pushViewController:vc animated:YES];
                        }
                    };
                __block  UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
                navi.modalPresentationStyle = UIModalPresentationFullScreen;
                [strongSelf.viewController.navigationController presentViewController:navi animated:YES completion:nil];
                              
//                };
            });
        }
    }];
}

-(void)getGroupList:(CDVInvokedUrlCommand*)command{
    __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        weakSelf.addGroupConvCommand =command;
        self.groupRefresh = NO;
        [weakSelf refreshGroupList];
    }];
}

-(void)enterGroupConv:(CDVInvokedUrlCommand*)command{
    __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        NSInteger  index = [[command argumentAtIndex:0] integerValue];
        WFCCGroupInfo *groupInfo = self.groupListArray[index];
        dispatch_async(dispatch_get_main_queue(), ^{
            WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
            NSString *groupId = groupInfo.target;
            mvc.conversation = [WFCCConversation conversationWithType:Group_Type target:groupId line:0];
            [weakSelf.viewController.navigationController pushViewController:mvc animated:YES];
        });
    }];
}

-(void)cancelGroupConv:(CDVInvokedUrlCommand*)command{
    __weak CDVIMFun* weakSelf = self;
     self.groupRefresh  = YES;
    [self.commandDelegate runInBackground:^{
        if ([command argumentAtIndex:0]) {
            NSInteger  index = [[command argumentAtIndex:0] integerValue];
            NSString *groupId = self.groupListArray[index].target;
            [[WFCCIMService sharedWFCIMService] setFavGroup:groupId fav:NO success:^{
                [weakSelf.viewController.view makeToast:@"取消成功" duration:2 position:CSToastPositionCenter];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf refreshGroupList];
                });
            } error:^(int error_code) {
                [weakSelf.viewController.view makeToast:@"取消失败" duration:2 position:CSToastPositionCenter];
            }];
        }
    }];
}

- (void)refreshGroupList {
    NSArray *ids = [[WFCCIMService sharedWFCIMService] getFavGroups];
    [self.groupListArray removeAllObjects];
    [self.groupListParamArray removeAllObjects];
    for (NSString *groupId in ids) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:groupId refresh:NO];
        if (groupInfo) {
            NSString *groupName = @"";
            NSString *imageStr = @"";
            groupInfo.target = groupId;
            if (groupInfo.portrait.length > 0) {
                imageStr = groupInfo.portrait;
            }
            if(groupInfo.name.length > 0) {
                groupName =  [NSString stringWithFormat:@"%@(%d)", groupInfo.name, (int)groupInfo.memberCount];
            } else {
                groupName = [NSString stringWithFormat:@"group<%@>",groupId];
            }
            NSDictionary *groupInfoDic = @{@"groupName":groupName,@"headImage":imageStr};
            [self.groupListParamArray addObject:groupInfoDic];
            [self.groupListArray addObject:groupInfo];
            if (!self.groupRefresh) {
                 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoListUpdated:) name:kGroupInfoUpdated object:groupId];
            }
        }
    }
    NSString *jsonResult;
    if (self.groupListParamArray.count>0) {
        jsonResult = [Utility dictionaryToJson:self.groupListParamArray];
    }else{
        jsonResult = @"[]";
    }
    if (self.groupRefresh) {
        NSString *jsStr = [NSString stringWithFormat:@"refreshGroupToVue('%@');",jsonResult];
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UIWebView*)self.webView  stringByEvaluatingJavaScriptFromString:jsStr];
        });
    }else{
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonResult];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.addGroupConvCommand.callbackId];
    }
}

- (void)onGroupInfoListUpdated:(NSNotification *)notification {
    self.groupRefresh  = YES;
    [self refreshGroupList];
}

-(void)addListenConversations:(CDVInvokedUrlCommand*)command{
    __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        NSInteger isLogin = [[command argumentAtIndex:0] integerValue];
        self.logined = isLogin;
        weakSelf.addConvCommand =command;
        self.popVC = NO;
        [weakSelf listenMessage];
    }];
}

-(void)logoutToSever:(CDVInvokedUrlCommand*)command{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
    [[WFCCNetworkService sharedInstance] disconnect:YES];
    self.logined =1;
}

-(void)loginToSever:(CDVInvokedUrlCommand*)command{
     __weak CDVIMFun* weakSelf = self;
    [self.commandDelegate runInBackground:^{
        NSString *user = [command argumentAtIndex:0];
        NSString *password = [command argumentAtIndex:1];
        NSString *parentId = [command argumentAtIndex:2];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self login:user password:password success:^(NSString *userId, NSString *token, BOOL newUser) {
                [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"savedName"];
                [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"savedToken"];
                [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"savedUserId"];
                [[NSUserDefaults standardUserDefaults] setObject:parentId forKey:@"savedParentId"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [[WFCCNetworkService sharedInstance] connect:userId token:token];
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"loginSuccess"];
                [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } error:^(int errCode, NSString *message) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
                [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                NSLog(@"login error with code %d, message %@", errCode, message);
            }];
        });
    }];
}
   

- (void)login:(NSString *)user password:(NSString *)password success:(void(^)(NSString *userId, NSString *token, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    [manager POST:[NSString stringWithFormat:@"http://%@:%d%@", APP_SERVER_HOST, APP_SERVER_PORT,@"/login"]
       parameters:@{@"mobile":user, @"code":password, @"clientId":[[WFCCNetworkService sharedInstance] getClientId]}
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSDictionary *dict = responseObject;
              if([dict[@"code"] intValue] == 0) {
                  NSString *userId = dict[@"result"][@"userId"];
                  NSString *token = dict[@"result"][@"token"];
                  BOOL newUser = [dict[@"result"][@"register"] boolValue];
                  successBlock(userId, token, newUser);
              } else {
                  errorBlock([dict[@"code"] intValue], dict[@"message"]);
              }
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              errorBlock(-1, error.description);
          }];
}

-(void)dealloc{
    self.addConvCommand =nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
