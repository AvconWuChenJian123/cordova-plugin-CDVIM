 var exec = require('cordova/exec');
    module.exports = {
        enterMessageVC:function(callbackSuccess,callbackError,options) {
          cordova.exec(callbackSuccess,callbackError,"IMFun","enterMessageVC",
              [options]);
        },
       sendMessageVC:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","sendMessageVC",
                    [options]);
       },
        createGroupVC:function(callbackSuccess,callbackError,options) {
           cordova.exec(callbackSuccess,callbackError,"IMFun","createGroupVC",
                            [options]);
            
       },
       addListenConversations:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","addListenConversations",
                    [options]);
       
       },
       loginToSever:function(callbackSuccess,callbackError,user,password,parentId) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","loginToSever",
                    [user,password,parentId]);
       
       },
       addFriendVC:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","addFriendVC",
                    [options]);
       
       },
       deleteMessage:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","deleteMessage",
                    [options]);
       
       },
       logoutToSever:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","logoutToSever",
                    [options]);
       
       },
       refreshUnreadCount:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","refreshUnreadCount",
                    [options]);
       
       },
       getGroupList:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","getGroupList",
                    [options]);
       
       },
       enterGroupConv:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","enterGroupConv",
                    [options]);
       
       },
       cancelGroupConv:function(callbackSuccess,callbackError,options) {
       cordova.exec(callbackSuccess,callbackError,"IMFun","cancelGroupConv",
                    [options]);
       
       }
               
    };
