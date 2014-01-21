//
//  ILCannedURLProtocol.m
//
//  Created by Claus Broch on 10/09/11.
//  Copyright 2011 Infinite Loop. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted
//  provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice, this list of conditions 
//    and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice, this list of 
//    conditions and the following disclaimer in the documentation and/or other materials provided 
//    with the distribution.
//  - Neither the name of Infinite Loop nor the names of its contributors may be used to endorse or 
//    promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ILCannedURLProtocol.h"

@interface NSMutableArray (QueueAdditions)
- (id) dequeue;
- (void) enqueue:(id)obj;
@end

@implementation NSMutableArray (QueueAdditions)
// Queues are first-in-first-out, so we remove objects from the head
- (id) dequeue {
    if ([self count] == 0) return nil; // to avoid raising exception (Quinn)
    id headObject = [self objectAtIndex:0];
    if (headObject != nil) {
        [[headObject retain] autorelease]; // so it isn't dealloc'ed on remove
        [self removeObjectAtIndex:0];
    }
    return headObject;
}

// Add to the tail of the queue (no one likes it when people cut in line!)
- (void) enqueue:(id)anObject {
    [self addObject:anObject];
    //this method automatically adds to the end of the array
}
@end

@implementation ILCannedResponse

- (id) init
{
    if (self = [super init]) {
        self.statusCode = 200;
        self.responseDelay = 0;
        self.error = nil;
    }
    return self;
}

- (id) initWithResponse:(NSData *)response
{
    if (self = [self init]) {
        self.data = response;
    }
    return self;
}

- (id) initWithResponseString:(NSString *)response
{
    return [self initWithResponse:[response dataUsingEncoding:NSUTF8StringEncoding]];
}

@end


// Undocumented initializer obtained by class-dump - don't use this in production code destined for the App Store
@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

static id<ILCannedURLProtocolDelegate> gILDelegate = nil;

static void(^startLoadingBlock)(NSURLRequest *request) = nil;
static NSMutableArray *gILCannedResponses = nil;
//static NSData *gILCannedResponseData = nil;
//static NSDictionary *gILCannedHeaders = nil;
//static NSInteger gILCannedStatusCode = 200;
//static NSError *gILCannedError = nil;
static NSArray *gILSupportedMethods = nil;
static NSArray *gILSupportedSchemes = nil;
static NSURL *gILSupportedBaseURL = nil;
//static CGFloat gILResponseDelay = 0;

@implementation ILCannedURLProtocol

+ (void)setStartLoadingBlock:(void(^)(NSURLRequest *request))block {
    Block_release(startLoadingBlock);
    startLoadingBlock = Block_copy(block);
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	
	BOOL canInit = YES;
	
	if (gILDelegate && [gILDelegate respondsToSelector:@selector(shouldInitWithRequest:)]) {
		canInit = [gILDelegate shouldInitWithRequest:request];
	} else {
		canInit = (
				   (!gILSupportedBaseURL || [request.URL.absoluteString hasPrefix:gILSupportedBaseURL.absoluteString]) &&
				   (!gILSupportedMethods || [gILSupportedMethods containsObject:request.HTTPMethod]) &&
				   (!gILSupportedSchemes || [gILSupportedSchemes containsObject:request.URL.scheme])
				   );
	}
	
	return canInit;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

+ (void)setDelegate:(id<ILCannedURLProtocolDelegate>)delegate {
	gILDelegate = delegate;
}

+ (NSMutableArray*) cannedResponseQueue
{
    if (gILCannedResponses == nil) {
        gILCannedResponses = [[[NSMutableArray alloc] init] retain];
    }
    return gILCannedResponses;
}

+ (void)setCannedResponse:(ILCannedResponse*) response
{
    [[ILCannedURLProtocol cannedResponseQueue] enqueue:response];
}

//+ (void)setCannedResponseData:(NSData*)data {
//	if(data != gILCannedResponseData) {
//		[gILCannedResponseData release];
//		gILCannedResponseData = [data retain];
//	}
//}

//+ (void)setCannedHeaders:(NSDictionary*)headers {
//	if(headers != gILCannedHeaders) {
//		[gILCannedHeaders release];
//		gILCannedHeaders = [headers retain];
//	}
//}

//+ (void)setCannedStatusCode:(NSInteger)statusCode {
//	gILCannedStatusCode = statusCode;
//}

//+ (void)setCannedError:(NSError*)error {
//	if(error != gILCannedError) {
//		[gILCannedError release];
//		gILCannedError = [error retain];
//	}
//}

- (NSCachedURLResponse *)cachedResponse {
	return nil;
}

+ (void)setSupportedMethods:(NSArray*)methods {
	if(methods != gILSupportedMethods) {
		[gILSupportedMethods release];
		gILSupportedMethods = [methods retain];
	}
}

+ (void)setSupportedSchemes:(NSArray*)schemes {
	if(schemes != gILSupportedSchemes) {
		[gILSupportedSchemes release];
		gILSupportedSchemes = [schemes retain];
	}
}

+ (void)setSupportedBaseURL:(NSURL*)baseURL {
	if(baseURL != gILSupportedBaseURL) {
		[gILSupportedBaseURL release];
		gILSupportedBaseURL = [baseURL retain];
	}
}


//+ (void)setResponseDelay:(CGFloat)responseDelay {
//	gILResponseDelay = responseDelay;
//}


- (void)startLoading {
    NSURLRequest *request = [self request];
	id<NSURLProtocolClient> client = [self client];
	
    if (startLoadingBlock) {
        startLoadingBlock(request);
    }
    
    ILCannedResponse *response = [[ILCannedURLProtocol cannedResponseQueue] dequeue];
    if (!response) {
        response = [[ILCannedResponse alloc] init];
    }
    
	NSInteger statusCode = [response statusCode];//gILCannedStatusCode;
	NSDictionary *headers = [response headers];//gILCannedHeaders;
	NSData *responseData = [response data];//gILCannedResponseData;
    NSError *error = [response error];
    CGFloat responseDelay = [response responseDelay];
    
    NSLog(@"Servicing: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
    
    // Handle redirects
    if (gILDelegate && [gILDelegate respondsToSelector:@selector(redirectForClient:request:)]) {
        NSURL *redirectUrl = [gILDelegate redirectForClient:client request:request];
        if (redirectUrl) {
            NSHTTPURLResponse *redirectResponse = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                              statusCode:302
                                                                            headerFields: [NSDictionary dictionaryWithObject:[redirectUrl absoluteString] forKey:@"Location"]
                                                                             requestTime:0.0];
            
            [client URLProtocol:self wasRedirectedToRequest:[NSURLRequest requestWithURL:redirectUrl] redirectResponse:redirectResponse];
            return;
        }
    }

	
	if (error) {
		[client URLProtocol:self didFailWithError:error];
		
	} else {
		
		if (gILDelegate && [gILDelegate respondsToSelector:@selector(responseDataForClient:request:)]) {
			
			if ([gILDelegate respondsToSelector:@selector(statusCodeForClient:request:)]) {
				statusCode  = [gILDelegate statusCodeForClient:client request:request];
			}
			
			if ([gILDelegate respondsToSelector:@selector(headersForClient:request:)]) {
				headers  = [gILDelegate headersForClient:client request:request];
			}
						
			responseData = [gILDelegate responseDataForClient:client request:request];
		}
		
		
		NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
											   statusCode:statusCode
											 headerFields:headers 
											  requestTime:0.0];
		
		[NSThread sleepForTimeInterval:responseDelay];
		//NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:gILResponseDelay];
		//[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil];
		
		
		[client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		[client URLProtocol:self didLoadData:responseData];
		[client URLProtocolDidFinishLoading:self];
		
		[response release];
	}
}

- (void)stopLoading {
}

@end
