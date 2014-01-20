//
//  ILCannedURLProtocolTests.m
//  TactilizeKit
//
//  Created by Arnaud Coomans on 03/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


//TODO urls should use example.com (ietf domain for example purposes)

#import "ILCannedURLProtocolTests.h"

@implementation ILCannedURLProtocolTests

- (void)setUp {
	[super setUp];
	
	[NSURLProtocol registerClass:[ILCannedURLProtocol class]];

	[ILCannedURLProtocol setDelegate:nil];
	
	[ILCannedURLProtocol setCannedStatusCode:200];
	[ILCannedURLProtocol setCannedHeaders:nil];
	[ILCannedURLProtocol setCannedResponseData:nil];
	[ILCannedURLProtocol setCannedError:nil];
	
	[ILCannedURLProtocol setSupportedMethods:nil];
	[ILCannedURLProtocol setSupportedSchemes:nil];
	[ILCannedURLProtocol setSupportedBaseURL:nil];
	
	[ILCannedURLProtocol setResponseDelay:0];
}

- (void)testCanInitWithGETHTTPRequestWithSupportedSchemesAndMethodsNotSet {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
	request.HTTPMethod = @"GET";
	
	[ILCannedURLProtocol setSupportedMethods:nil];
	[ILCannedURLProtocol setSupportedSchemes:nil];
	
	XCTAssertTrue([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol does not support a GET HTTP request");
}

- (void)testCanInitWithGETHTTPRequestWithSupportedSchemesAndMethodsEmpty {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
	request.HTTPMethod = @"GET";
	
	[ILCannedURLProtocol setSupportedMethods:[NSArray array]];
	[ILCannedURLProtocol setSupportedSchemes:[NSArray array]];
	
	XCTAssertFalse([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol does not support a GET HTTP request");
}

- (void)testCanInitWithGETHTTPRequestWithSupportedHTTPSchemesAndGETMethods{
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
	request.HTTPMethod = @"GET";
	
	[ILCannedURLProtocol setSupportedMethods:[NSArray arrayWithObject:@"GET"]];
	[ILCannedURLProtocol setSupportedSchemes:[NSArray arrayWithObject:@"http"]];
	
	XCTAssertTrue([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol does not support a GET HTTP request");
}

- (void)testCanInitWithPOSTHTTPSRequestWithSupportedHTTPSSchemesAndPOSTMethods{
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com"]];
	request.HTTPMethod = @"POST";
	
	[ILCannedURLProtocol setSupportedMethods:[NSArray arrayWithObject:@"POST"]];
	[ILCannedURLProtocol setSupportedSchemes:[NSArray arrayWithObject:@"https"]];
	
	XCTAssertTrue([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol does not support a GET HTTP request");
}

- (void)testCanInitWithPOSTHTTPRequestWithSupportedHTTPSchemesAndGETMethods{
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
	request.HTTPMethod = @"POST";
	
	[ILCannedURLProtocol setSupportedMethods:[NSArray arrayWithObject:@"GET"]];
	[ILCannedURLProtocol setSupportedSchemes:[NSArray arrayWithObject:@"http"]];
	
	XCTAssertFalse([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol does not support a GET HTTP request");
}

- (void)testCanInitWithGETHTTPRequestWithSupportedHTTPSSchemesAndGETMethods{
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
	request.HTTPMethod = @"GET";
	
	[ILCannedURLProtocol setSupportedMethods:[NSArray arrayWithObject:@"GET"]];
	[ILCannedURLProtocol setSupportedSchemes:[NSArray arrayWithObject:@"https"]];
	
	XCTAssertFalse([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol does not support a GET HTTP request");
}

- (void)testCanInitWithRequestWithSupportedBaseURL {
	
	NSMutableURLRequest *goodRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/testCanInitWithRequestWithSupportedBaseURL"]];
	NSMutableURLRequest *badRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.org"]];
	
	[ILCannedURLProtocol setSupportedBaseURL:[NSURL URLWithString:@"http://example.com"]];
	
	XCTAssertTrue([ILCannedURLProtocol canInitWithRequest:goodRequest], @"ILCannedURLProtocol does not support a request with base url");
	XCTAssertFalse([ILCannedURLProtocol canInitWithRequest:badRequest], @"ILCannedURLProtocol does not support a request with base url");
}


- (void)testStartLoadingWithoutDelegate {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com"]];
	
	id requestObject = [NSDictionary dictionaryWithObjectsAndKeys:
				 [NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:1], [NSNumber numberWithInt:2], nil], @"array", 
				 @"hello", @"string",
				 nil];
				 
	NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestObject options:0 error:nil];
	[ILCannedURLProtocol setCannedResponseData:requestData];
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
	
	XCTAssertNotNil(responseObject, @"no canned response from http request");
	XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]], @"canned response has wrong format (not dictionary)");	
}

- (void)testStartLoadingWithDelegate {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/testStartLoadingWithDelegate"]];
	
	[ILCannedURLProtocol setDelegate:self];
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
	
	XCTAssertNotNil(responseObject, @"no canned response from http request");
	XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]], @"canned response has wrong format (not dictionary)");
	XCTAssertTrue([[responseObject objectForKey:@"testName"] isEqual:@"testStartLoadingWithDelegate"], @"wrong canned response");
}

- (void)testAgainStartLoadingWithDelegate {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/testAgainStartLoadingWithDelegate"]];
	
	[ILCannedURLProtocol setDelegate:self];
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
	
	XCTAssertNotNil(responseObject, @"no canned response from http request");
	XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]], @"canned response has wrong format (not dictionary)");
	XCTAssertTrue([[responseObject objectForKey:@"testName"] isEqual:@"testAgainStartLoadingWithDelegate"], @"wrong canned response");
}

- (void)testStartLoadingWithDelegatePlainJSONResponse {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/testStartLoadingWithDelegatePlainJSONResponse"]];
	
	[ILCannedURLProtocol setDelegate:self];
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
	
	XCTAssertNotNil(responseObject, @"no canned response from http request");
	XCTAssertTrue([responseObject isKindOfClass:[NSDictionary class]], @"canned response has wrong format (not dictionary)");
	XCTAssertTrue([[responseObject objectForKey:@"testName"] isEqual:@"testStartLoadingWithDelegatePlainJSONResponse"], @"wrong canned response");
}

- (void)testCanInitWithRequestWithDelegateShouldInitWithRequest {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/testCanInitWithRequestWithDelegateShouldInitWithRequest"]];
	
	[ILCannedURLProtocol setDelegate:self];
	
	XCTAssertTrue([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol delegate returned shouldInitWithRequest NO");
}

- (void)testCanInitWithRequestWithDelegateShouldInitWithRequestNO {
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://example.com/testCanInitWithRequestWithDelegateShouldInitWithRequestNO"]];
	
	[ILCannedURLProtocol setDelegate:self];
	
	XCTAssertFalse([ILCannedURLProtocol canInitWithRequest:request], @"ILCannedURLProtocol delegate returned shouldInitWithRequest YES");
}


- (void)testRedirectForClient {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://redirect-test.com"]];
    
    [ILCannedURLProtocol setDelegate:self];
    
    NSURLResponse *response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	id responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
	
    XCTAssertNotNil(response, @"no canned response from http request");
	XCTAssertNotNil(responseObject, @"no canned response object from http request");
    XCTAssertEqualObjects(response.URL.absoluteString, @"http://redirected-response.com", @"response should have been redirected");
    XCTAssertTrue([[responseObject objectForKey:@"REDIRECTED"] isEqual:@"YES"], @"wrong canned response");
}



#pragma mark - ILCannedURLProtocolDelegate

- (NSURL *)redirectForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest *)request
{
    if ([request.HTTPMethod isEqualToString:@"GET"] && [request.URL.absoluteString isEqualToString:@"http://redirect-test.com"]) {
        return [NSURL URLWithString:@"http://redirected-response.com"];
    }
    
    return nil;
}

- (NSData*)responseDataForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest*)request {
	
	NSData *requestData = nil;
	
	if ([request.URL.absoluteString isEqual:@"http://example.com/testStartLoadingWithDelegate"]) {
		id requestObject = [NSDictionary dictionaryWithObjectsAndKeys:@"testStartLoadingWithDelegate", @"testName", nil];
		requestData = [NSJSONSerialization dataWithJSONObject:requestObject options:0 error:nil];
	
	}
	
	if ([request.URL.absoluteString isEqual:@"http://example.com/testAgainStartLoadingWithDelegate"]) {
		id requestObject = [NSDictionary dictionaryWithObjectsAndKeys:@"testAgainStartLoadingWithDelegate", @"testName", nil];
		requestData = [NSJSONSerialization dataWithJSONObject:requestObject options:0 error:nil];
			
	}
	
	if ([request.URL.absoluteString isEqual:@"http://example.com/testStartLoadingWithDelegatePlainJSONResponse"]) {
		requestData = [@"{\"testName\":\"testStartLoadingWithDelegatePlainJSONResponse\"}" dataUsingEncoding:NSUnicodeStringEncoding];
	}
    
    if ([request.URL.absoluteString isEqual:@"http://redirected-response.com"]) {
        id requestObject = [NSDictionary dictionaryWithObject:@"YES" forKey:@"REDIRECTED"];
		requestData = [NSJSONSerialization dataWithJSONObject:requestObject options:0 error:nil];
    }
	
	
	return requestData;
}


- (BOOL)shouldInitWithRequest:(NSURLRequest*)request {
	if ([request.URL.absoluteString isEqual:@"http://example.com/testCanInitWithRequestWithDelegateShouldInitWithRequest"]) {
		return YES;
	}
	
	if ([request.URL.absoluteString isEqual:@"http://example.com/testCanInitWithRequestWithDelegateShouldInitWithRequestNO"]) {
		return NO;
	}
	
	return YES;
}


@end
