#import "OBAModelServiceRequest.h"
#import "UIDeviceExtensions.h"


@implementation OBAModelServiceRequest

@synthesize delegate = _delegate;
@synthesize context = _context;
@synthesize modelFactory = _modelFactory;
@synthesize modelFactorySelector = _modelFactorySelector;

@synthesize checkCode = _checkCode;

@synthesize bgTask = _bgTask;
@synthesize connection = _connection;

- (id) init {
	if( self = [super init] ) {
		_checkCode = TRUE;
		if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
            _bgTask = UIBackgroundTaskInvalid;
	}
	return self;
}

- (void) dealloc {
	[_connection release];
	[_context release];
	[_modelFactory release];
	[super dealloc];
}

- (void) handleResult:(id)obj {
	
	if( _checkCode ) {
		NSNumber * code = [obj valueForKey:@"code"];
	
		if( code == nil || [code intValue] != 200 ) {
			if( [_delegate respondsToSelector:@selector(requestDidFinish:withCode:context:)] )
				[_delegate requestDidFinish:self withCode:[code intValue] context:_context];
			return;
		}
		
		obj = [obj valueForKey:@"data"];
	}
	
	NSDictionary * data = obj;
	NSError * error = nil;
	NSError ** errorRef = &error;
	
	id result = nil;
	
	if( ! [_modelFactory respondsToSelector:_modelFactorySelector] )
		return;
	
	NSMethodSignature * sig = [_modelFactory methodSignatureForSelector:_modelFactorySelector];
	NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:sig];
	[invocation setTarget:_modelFactory];
	[invocation setSelector:_modelFactorySelector];
	[invocation setArgument:&data atIndex:2];
	[invocation setArgument:&errorRef atIndex:3];
	[invocation invoke];
	
	if( error ) {
		if( [_delegate respondsToSelector:@selector(requestDidFail:withError:context:)] )
			[_delegate requestDidFail:self withError:error context:_context];
		return;
	}
	
	[invocation getReturnValue:&result];
	[_delegate requestDidFinish:self withObject:result context:_context];
}

// check if we support background task completion; if so, end bg task
- (void) endBackgroundTask {		
	if ([[UIDevice currentDevice] isMultitaskingSupportedSafe]) {
		if (_bgTask != UIBackgroundTaskInvalid) {
			UIApplication* app = [UIApplication sharedApplication];
			[app endBackgroundTask:_bgTask];
			_bgTask = UIBackgroundTaskInvalid;   
		}
	}
}


#pragma mark OBAModelServiceRequest

- (void) cancel {
	[_connection cancel];
	[self endBackgroundTask];
}

#pragma mark OBADataSourceDelegate

- (void) connectionDidFinishLoading:(id<OBADataSourceConnection>)connection withObject:(id)obj context:(id)context {
	[self handleResult:obj];
	[self endBackgroundTask];
}

- (void) connectionDidFail:(id<OBADataSourceConnection>)connection withError:(NSError *)error context:(id)context {
	if( [_delegate respondsToSelector:@selector(requestDidFail:withError:context:)] )	
		[_delegate requestDidFail:self withError:error context:_context];
	[self endBackgroundTask];
}

- (void) connection:(id<OBADataSourceConnection>)connection withProgress:(float)progress {
	if( [_delegate respondsToSelector:@selector(request:withProgress:context:)] )
		[_delegate request:self withProgress:progress context:_context];
	[self endBackgroundTask];
}

@end
