//
//  CDVIMFun.h
//  移动平台门户客户端
//
//  Created by wuchenjian on 2019/8/8.
//

#import <Cordova/CDVPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface CDVIMFun : CDVPlugin

-(void)enterMessageVC:(CDVInvokedUrlCommand*)command;
-(void)createGroupVC:(CDVInvokedUrlCommand*)command;
-(void)addFriendVC:(CDVInvokedUrlCommand*)command;
-(void)deleteMessage:(CDVInvokedUrlCommand*)command;
-(void)addListenConversations:(CDVInvokedUrlCommand*)command;
-(void)loginToSever:(CDVInvokedUrlCommand*)command;
-(void)logoutToSever:(CDVInvokedUrlCommand*)command;
-(void)sendMessageVC:(CDVInvokedUrlCommand*)command;
-(void)refreshUnreadCount:(CDVInvokedUrlCommand*)command;
-(void)getGroupList:(CDVInvokedUrlCommand*)command;
-(void)enterGroupConv:(CDVInvokedUrlCommand*)command;
-(void)cancelGroupConv:(CDVInvokedUrlCommand*)command;

@end

NS_ASSUME_NONNULL_END
