//  Copyright 2011年 Renren Inc. All rights reserved.
//  - Powered by Team Pegasus. -
//
#import <CommonCrypto/CommonDigest.h>
#import "ROConnect.h"
#import "JSON.h"
#import "ROCreateAlbumResponseItem.h"
#import "ROUserResponseItem.h"
#import "ROUtility.h"
#import "ROPublishPhotoRequestParam.h"
#import "RODialog.h"
#import "RORequest.h"
#import "Renren.h"

@interface Renren(Private)

- (void)setGeneralRequestArgs:(RORequestParam *)inRequestParam;

- (void)getLoggedInUserId;
// 新方法。
- (void)sendRequestWithUrl:(NSString *)url param:(RORequestParam *)param httpMethod:(NSString *)httpMethod delegate:(id<RORequestDelegate>)delegate;

// 旧方法。
- (RORequest*)openUrl:(NSString *)url params:(NSMutableDictionary *)params httpMethod:(NSString *)httpMethod delegate:(id<RORequestDelegate>)delegate;

- (NSString *)getSecretKeyByToken:(NSString *)token;
- (NSString *)getSessionKeyByToken:(NSString *)token;


/**
 * 删除当前用户登录状态
 */
- (void)delUserSessionInfo;

- (void)authorizeWithRRAppAuth:(BOOL)tryRRAppAuth safariAuth:(BOOL)trySafariAuth;

@end

@implementation Renren

@synthesize accessToken = _accessToken;
@synthesize expirationDate = _expirationDate;
@synthesize secret=_secret;
@synthesize sessionKey=_sessionKey;
@synthesize appKey = _appKey;
@synthesize appId = _appId;
@synthesize renrenDelegate = _renrenDelegate;
@synthesize permissions = _permissions;


#pragma mark - Construction & Destruction -

static Renren *sharedRenren = nil;

/**
 * Override NSObject : release the data members. 
 */
- (void)dealloc {
	[_accessToken release];
	[_expirationDate release];
	[_request release];
	[_rrDialog release];
	[_appId release];
	self.appKey = nil;
	[_secret release];
	[_permissions release];
	[_sessionKey release];
	[super dealloc];
}

+ (Renren *)newRenRen{
    Renren *newRenrenObject = [[Renren alloc] init];
    [newRenrenObject isSessionValid];
    newRenrenObject.appKey = SHKCONFIG(renrenConsumerKey);
    newRenrenObject.appId = SHKCONFIG(renrenAppId);
    return [newRenrenObject autorelease];
}

+ (Renren *)sharedRenren {
    if (!sharedRenren) {
        sharedRenren = [[Renren alloc] init];
        [sharedRenren isSessionValid];
        sharedRenren.appKey = SHKCONFIG(renrenConsumerKey);
        sharedRenren.appId = SHKCONFIG(renrenAppId);
    }
    return sharedRenren;
}

#pragma mark - General Public Methods -

-(BOOL)isSessionValid{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (nil != defaults){
		self.accessToken = [defaults objectForKey:@"access_Token"];
		self.expirationDate = [defaults objectForKey:@"expiration_Date"];
		self.sessionKey = [defaults objectForKey:@"session_Key"];
		self.secret = [defaults objectForKey:@"secret_Key"];
	}
    return (self.accessToken != nil && self.expirationDate != nil && self.sessionKey != nil && NSOrderedDescending == [self.expirationDate compare:[NSDate date]]);	
}


#pragma mark - Private Methods -

/**
 * 保存用户经oauth 2.0登录后的信息,到UserDefaults中。
 */
-(void)saveUserSessionInfo{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
    if (self.accessToken) {
        [defaults setObject:self.accessToken forKey:@"access_Token"];
    }
	if (self.expirationDate) {
		[defaults setObject:self.expirationDate forKey:@"expiration_Date"];
	}	
    if (self.sessionKey) {
        [defaults setObject:self.sessionKey forKey:@"session_Key"];
        [defaults setObject:self.secret forKey:@"secret_Key"];
    }
	
    [defaults synchronize];	
}

/**
 * 删除UserDefaults中保存的用户oauth 2.0信息 
 */
-(void)delUserSessionInfo{
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"access_Token"];
	[defaults removeObjectForKey:@"secret_Key"];
	[defaults removeObjectForKey:@"session_Key"];
	[defaults removeObjectForKey:@"expiration_Date"];
    [defaults removeObjectForKey:@"session_UserId"];
	NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray* graphCookies = [cookies cookiesForURL:
                             [NSURL URLWithString:@"http://graph.renren.com"]];
	
	for (NSHTTPCookie* cookie in graphCookies) {
		[cookies deleteCookie:cookie];
	}
	NSArray* widgetCookies = [cookies cookiesForURL:[NSURL URLWithString:@"http://widget.renren.com"]];
	
	for (NSHTTPCookie* cookie in widgetCookies) {
		[cookies deleteCookie:cookie];
	}
	[defaults synchronize];
}

- (void)getLoggedInUserId{
  	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"session_UserId"]) {
        return;
    }
    RORequestParam * param = [[[RORequestParam alloc] init] autorelease];
    param.method = @"users.getLoggedInUser";
	[self requestWithParam:param andDelegate:self];
    
}
// 新的接口。
- (void)sendRequestWithUrl:(NSString *)url param:(RORequestParam *)param httpMethod:(NSString *)httpMethod delegate:(id<RORequestDelegate>)delegate{
    [_request release];
    
    delegate = delegate?delegate:self;
    _request = [[RORequest getRequestWithParam:param httpMethod:httpMethod delegate:delegate requestURL:url] retain];
    [_request connect];
    return;
}

// 旧的接口
- (RORequest*)openUrl:(NSString *)url params:(NSMutableDictionary *)params httpMethod:(NSString *)httpMethod delegate:(id<RORequestDelegate>)delegate{
    [_request release];
    
    delegate = delegate?delegate:self;
    _request = [[RORequest getRequestWithParams:params httpMethod:httpMethod delegate:delegate requestURL:url] retain];
    [_request connect];
    return _request;
}

- (void)requestWithParam:(RORequestParam *)param andDelegate:(id <RORequestDelegate>)delegate {
    if (nil == param.method || [param.method length] <= 0) {
        NSLog(@"API Method must be specified");
        return;
    }
    
    if (![self isSessionValid]) {
        NSLog(@"Session is not valid! Request abort!!");
        return;
    }
    
    [self setGeneralRequestArgs:param];
    
    [self sendRequestWithUrl:kRestserverBaseURL param:param httpMethod:@"POST" delegate:delegate];
	
    return;
}

#pragma mark - RODialogDelegate Methods -

- (void)authDialog:(RODialog *)dialog withOperateType:(RODialogOperateType )operateType{
    if (dialog != _rrDialog) {
        return;
    }
    NSDictionary* authDictionary = nil;
    ROError* authError = nil;
    switch (operateType) {
        case RODialogOperateSuccess:
            authDictionary = (NSDictionary *)dialog.response.rootObject;
            NSString* token = [authDictionary objectForKey:@"token"];
            NSDate* expirationDate = [authDictionary objectForKey:@"expirationDate"];
            self.accessToken = token;
            self.expirationDate = expirationDate;
            self.secret=[self getSecretKeyByToken:token];
            self.sessionKey=[self getSessionKeyByToken:token];	
            //用户信息保存到本地
            [self saveUserSessionInfo];	
            [self getLoggedInUserId];
            if ([_renrenDelegate respondsToSelector:@selector(renrenDidLogin:)]) {  
                [_renrenDelegate renrenDidLogin:self];
            }
            break;
        case RODialogOperateFailure:
            authError = dialog.response.error;
            if ([_renrenDelegate respondsToSelector:@selector(renren:loginFailWithError:)]) {
                 [_renrenDelegate renren:self loginFailWithError:authError];
            }
            break;
        default:
            if ([_renrenDelegate respondsToSelector:@selector(renrenDialogDidCancel:)]) {
                 [_renrenDelegate renrenDialogDidCancel:self];
            }
            break;
    }
    
}

- (void)widgetDialog:(RODialog *)dialog withOperateType:(RODialogOperateType )operateType{
    if (dialog != _rrDialog) {
        return;
    }
    switch (operateType) {
        case RODialogOperateSuccess:
            if ([_renrenDelegate respondsToSelector:@selector(renren:requestDidReturnResponse:)]) {
                [_renrenDelegate renren:self requestDidReturnResponse:dialog.response];
            }
            break;
        case RODialogOperateFailure:
            if([_renrenDelegate respondsToSelector:@selector(renren:requestFailWithError:)]){
                [_renrenDelegate renren:self requestFailWithError:dialog.response.error];
            }
            break;
        default:
            if ([_renrenDelegate respondsToSelector:@selector(renrenDialogDidCancel:)]) {
                [_renrenDelegate renrenDialogDidCancel:self];
            }
            break;
    }
}

#pragma mark - Util Methods -
/*
 * 用于设置通用的一些参数到param对象中。
 */
-(void)setGeneralRequestArgs: (RORequestParam *)inRequestParam{
    // 这里假设此前已经调用[self isSessionValid],并且返回Ture。
    inRequestParam.sessionKey = self.sessionKey;
    inRequestParam.apiKey = self.appKey;
    inRequestParam.callID = [ROUtility generateCallId];
    inRequestParam.xn_ss = @"1";
    inRequestParam.format = @"json";
    inRequestParam.apiVersion = kSDKversion;
	
    inRequestParam.sig = [ROUtility generateSig:[inRequestParam requestParamToDictionary] secretKey:self.secret]; 
}

/**
 * 用accesstoken 获取调用api 时用到的参数session_secret
 */
-(NSString *)getSecretKeyByToken:(NSString *)token{
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   token, @"oauth_token",
								   nil];
	NSString *getKeyUrl = [RORequest serializeURL:kRRSessionKeyURL params:params];
    id result = [RORequest getRequestSessionKeyWithParams:getKeyUrl];
	if ([result isKindOfClass:[NSDictionary class]]) {
		NSString* secretkey=[[result objectForKey:@"renren_token"] objectForKey:@"session_secret"];
		return secretkey;
	}
	return nil;
}

/**
 * 用accesstoken 获取调用api 时用到的参数session_key
 */
-(NSString *)getSessionKeyByToken:(NSString *)token{
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   token, @"oauth_token",
								   nil];
	NSString *getKeyUrl = [RORequest serializeURL:kRRSessionKeyURL params:params];
    id result = [RORequest getRequestSessionKeyWithParams:getKeyUrl];
	if ([result isKindOfClass:[NSDictionary class]]) {
		NSString* sessionkey=[[result objectForKey:@"renren_token"] objectForKey:@"session_key"];
		return sessionkey;
	}
	return nil;
}


#pragma mark - Authorize & Logout -

/*
 * 用户oauth2登录请求认证授权
 */
- (void)authorizationWithPermisson:(NSArray *)permissions andDelegate:(id<RenrenDelegate>)delegate {
    /*NSLog(@"正在通过OAuth 2.0请求认证授权......");
    self.permissions = permissions;
    self.renrenDelegate = delegate;
    if (![self isSessionValid]){
        [self authorizeWithRRAppAuth:YES safariAuth:YES]; 
    }*/
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray* graphCookies = [cookies cookiesForURL:
                             [NSURL URLWithString:@"http://graph.renren.com"]];
	
	for (NSHTTPCookie* cookie in graphCookies) {
		[cookies deleteCookie:cookie];
	}
	NSArray* widgetCookies = [cookies cookiesForURL:[NSURL URLWithString:@"http://widget.renren.com"]];
	
	for (NSHTTPCookie* cookie in widgetCookies) {
		[cookies deleteCookie:cookie];
	}
    if (![self isSessionValid]) {
        self.renrenDelegate = [delegate retain];
        self.permissions = nil;
        self.permissions = permissions;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setValue:_appKey forKey:@"client_id"];
        [parameters setValue:kRRSuccessURL forKey:@"redirect_uri"];
        [parameters setValue:@"token" forKey:@"response_type"];
        [parameters setValue:@"touch" forKey:@"display"];
        if (nil != self.permissions) {
            NSString *permissionScope = [self.permissions componentsJoinedByString:@","];
            [parameters setValue:permissionScope forKey:@"scope"];
        }
        
        [_rrDialog release];
        NSLog(@"正在通过OAuth 2.0请求认证授权......");
        _rrDialog = [[RODialog alloc] initWithURL:kAuthBaseURL params:parameters delegate:self];
        [_rrDialog show];
    }
}

- (void)passwordFlowAuthorizationWithParam:(ROPasswordFlowRequestParam *)param andDelegate:(id<RenrenDelegate>) delegate{
	self.renrenDelegate = delegate;
	
	param.apiKey = self.appKey;
	
	if (![self isSessionValid]){
		[self sendRequestWithUrl:kPasswordFlowBaseURL param:param httpMethod:@"POST" delegate:self];
	}
}

/**
 * 退出用户登录
 *
 * @param delegate
 *          
 */

- (void)logout:(id<RenrenDelegate>)delegate {
    self.renrenDelegate = delegate;
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params release];
    [_accessToken release];
    _accessToken = nil;
    [_expirationDate release];
    _expirationDate = nil;
    [_secret release];
    _secret=nil;
    [_sessionKey release];
    _sessionKey=nil;
    [self delUserSessionInfo];
    if ([self.renrenDelegate respondsToSelector:@selector(renrenDidLogout:)]) {
        [self.renrenDelegate renrenDidLogout:self];
    }
}

#pragma mark - Customlized API Request Methods -

- (RORequest *)requestWithParams:(NSMutableDictionary *)params andDelegate:(id <RenrenDelegate>)delegate{
    if (nil == [params objectForKey:@"method"]) {
        NSLog(@"API Method must be specified");
        return nil;
    }
	if ([self isSessionValid]) {
		[params setObject:self.sessionKey forKey:@"session_key"];
    }else {
		NSLog(@"Session is not valid! Request abort!!");
		return nil;
	}
	
	[params setObject:[ROUtility generateCallId] forKey:@"call_id"];//增加键与值
	[params setObject:_appKey forKey:@"api_key"];	
	[params setObject:kSDKversion forKey:@"v"];
	[params setObject:@"json" forKey:@"format"];
	[params setObject:@"1" forKey:@"xn_ss"];
	
	NSString *sig = [ROUtility generateSig:params secretKey:self.secret];
	[params setObject:sig forKey:@"sig"];
    
    self.renrenDelegate = [delegate retain];
    
    return [self openUrl:kRestserverBaseURL params:params httpMethod:@"POST" delegate:self];	
}

- (void)dialog:(NSString *)action andParams:(NSMutableDictionary *)params andDelegate:(id<RenrenDelegate>)delegate{
	NSString *dialogURL = [kDialogBaseURL stringByAppendingString:action];
	[params setObject:_appId forKey:@"app_id"];
	[params setObject:@"touch" forKey:@"display"];
	
	if ([params objectForKey:@"redirect_uri"] == nil) {
		[params setObject:kRRSuccessURL forKey:@"redirect_uri"];
    }
    
	if ([self isSessionValid]) {
        [params setValue:[self.accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:@"access_token"];
    }
	
	_renrenDelegate = delegate;
	[_rrDialog release];
	_rrDialog = [[RODialog alloc] initWithURL:dialogURL params:params delegate:self];
	[_rrDialog show];
}

#pragma mark - RORequestDelegate -

/**
 * Handle the auth.ExpireSession api call failure
 */
- (void)request:(RORequest *)request didFailWithError:(NSError*)error{
    NSLog(@"Failed to expire the session");
}

- (void)request:(RORequest *)request didFailWithROError:(ROError *)error{
    
	//password flow授权错误的处理
	if([request.requestParamObject isKindOfClass:[ROPasswordFlowRequestParam class]])
	{
		if ([self.renrenDelegate respondsToSelector:@selector(renren:loginFailWithError:)]) {  
			[self.renrenDelegate renren:self loginFailWithError:error];
		}else{
			// 默认错误处理。
			NSString *title = [NSString stringWithFormat:@"Error code:%d", [error code]];
			NSString *description = [NSString stringWithFormat:@"%@", [error localizedDescription]];
			UIAlertView *alertView =[[[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] autorelease];
			[alertView show];
		}
		return;
	}
	
	if (self.renrenDelegate && [self.renrenDelegate respondsToSelector:@selector(renren:requestFailWithError:)]) {
        [self.renrenDelegate renren:self requestFailWithError:error];
    }else{
        // 默认错误处理。
        NSString *title = [NSString stringWithFormat:@"Error code:%d", [error code]];
        NSString *description = [NSString stringWithFormat:@"%@", [error localizedDescription]];
        UIAlertView *alertView =[[[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] autorelease];
        [alertView show];
    }
    
    return;
}

- (void)request:(RORequest *)request didLoad:(id)result{
	
	//password flow授权请求的处理
	if([request.requestParamObject isKindOfClass:[ROPasswordFlowRequestParam class]])
	{
		NSString *token = [request.responseObject.rootObject objectForKey:@"access_token"];
		NSString *date = [request.responseObject.rootObject objectForKey:@"expires_in"];
			 
		self.accessToken = [request.responseObject.rootObject objectForKey:@"access_token"];;
		self.expirationDate = [ROUtility getDateFromString:date];
		self.secret=[self getSecretKeyByToken:token];
		self.sessionKey=[self getSessionKeyByToken:token];	
		//用户信息保存到本地
		[self saveUserSessionInfo];	
        [self getLoggedInUserId];
		if ([self.renrenDelegate respondsToSelector:@selector(renrenDidLogin:)]) {  
			[self.renrenDelegate renrenDidLogin:self];
		}
		return;
	}
    if ([request.requestParamObject.method isEqualToString:@"users.getLoggedInUser"]) {
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSNumber *uid = [(NSDictionary*)result objectForKey:@"uid"];
        if (uid) {
            [defaults setObject:[uid stringValue] forKey:@"session_UserId"];
            [defaults synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationDidGetLoggedInUserId" object:nil];
        }
        
        return;
    }
    if(self.renrenDelegate && [self.renrenDelegate respondsToSelector:@selector(renren:requestDidReturnResponse:)]){
        [self.renrenDelegate renren:self requestDidReturnResponse:request.responseObject];     
    }else{
        // 默认请求成功时的处理。
        
    }
    
    return;
}

#pragma mark - Packaged API Function Methods -

-(void)createAlbum:(ROCreateAlbumRequestParam *)param andDelegate:(id<RenrenDelegate>)delegate{
	if (![param.method isEqualToString:@"photos.createAlbum"]) {
		NSLog(@"API Method Error!");
		return;
    }
	
	self.renrenDelegate = delegate;
	
	[self requestWithParam:param andDelegate:self];
    
    return;
}

-(void)getAlbums:(ROAlbumsInfoRequestParam *)param andDelegate:(id<RenrenDelegate>)delegate{
	if (![param.method isEqualToString:@"photos.getAlbums"]) {
		NSLog(@"API Method Error!");
		return;
    }
	
	self.renrenDelegate = delegate;
	
	[self requestWithParam:param andDelegate:self];
    
    return;
}

-(void)getUsersInfo:(ROUserInfoRequestParam *)param andDelegate:(id<RenrenDelegate>)delegate{
	if (![param.method isEqualToString:@"users.getInfo"]) {
		NSLog(@"API Method Error!");
		return;
    }
	
	self.renrenDelegate = delegate;
	
	[self requestWithParam:param andDelegate:self];
    
    return;
}

-(void)publishPhoto:(ROPublishPhotoRequestParam *)param andDelegate:(id<RenrenDelegate>)delegate{
    if (![param.method isEqualToString:@"photos.upload"]) {
		NSLog(@"API Method Error!");
		return;
    }
	
	self.renrenDelegate = delegate;
	
	[self requestWithParam:param andDelegate:self];
    
    return;
}

-(void)getFriends:(ROGetFriendsRequestParam *)param andDelegate:(id<RenrenDelegate>)delegate
{
	if (![param.method isEqualToString:@"friends.get"]) {
		NSLog(@"API Method Error!");
		return;
    }
	
	self.renrenDelegate = delegate;
	
	[self requestWithParam:param andDelegate:self];
}

-(void)getFriendsInfo:(ROGetFriendsInfoRequestParam *)param andDelegate:(id<RenrenDelegate>)delegate
{
	if (![param.method isEqualToString:@"friends.getFriends"]) {
		NSLog(@"API Method Error!");
		return;
    }
	
	if (![self isSessionValid]) {
		//[self delUserSessionInfo];
		NSLog(@"Session not valid!! Request abort!");
		return;
	}
	
	self.renrenDelegate = delegate;
	
	[self requestWithParam:param andDelegate:self];
}

#pragma mark - One-Click API Function Methods -
/**
 *一键发布照片流程方法
 *@param image 准备上传图片对象
 *@param caption 上传图片的附加文本，会成为照片的描述
 */
-(void)publishPhotoSimplyWithImage:(UIImage *)image caption:(NSString *)caption
{
    
    ROPublishPhotoDialogModel *dialogModel = [ROPublishPhotoDialogModel modelWithRenren:self];
    dialogModel.photo = image;
    dialogModel.caption = caption;
    RODialogView *dialogView = [RODialogView dialogViewWithModel:dialogModel];
    //判断用户是否已通过授权认证
    if (![self isSessionValid]) {
        [dialogView waitForRenrenAuthorize];
        NSArray *permissions = [NSArray arrayWithObjects:@"photo_upload",nil];
        [self authorizationWithPermisson:permissions andDelegate:dialogModel];
    }else {
        [dialogView show:YES];
    }    
}

#pragma mark - discarded Methods should removed in near future -

/**
 * A private function for opening the authorization dialog.
 * User-Agent Flow
 */
- (void)authorizeWithRRAppAuth:(BOOL)tryRRAppAuth safariAuth:(BOOL)trySafariAuth {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   _appKey, @"client_id",
                                   @"token", @"response_type",
                                   kRRSuccessURL, @"redirect_uri",
                                   @"touch", @"display",
                                   nil];
    if (_permissions != nil){
        NSString* scope = [_permissions componentsJoinedByString:@","];
        [params setValue:scope forKey:@"scope"];
    }
    
	[_rrDialog release];
	_rrDialog = [[RODialog alloc] initWithURL:kAuthBaseURL params:params delegate:self];
	[_rrDialog show];
    
}

@end
