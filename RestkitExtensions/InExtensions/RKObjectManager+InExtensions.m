//
//  RKObjectManager+InExtensions.m
//
//  Created by Hernan Gabriel Gonzalez on 1/11/14.
//  Copyright (c) 2014 Indeba.com. All rights reserved.
//

#import "RKObjectManager+InExtensions.h"
#import "RKObjectMapping+InExtensions.h"
#import <RKErrorMessage.h>
#import <RestKit/Network.h>

#define kRequestMapping     @"request"
#define kResponseMapping    @"response"
#define kMappingInfo        @"mapping"
#define kStatusCode         @"statusCode"
#define kMappingClass       @"class"
#define kPathPattern        @"pathPattern"
#define kKeyPath            @"keyPath"
#define kMappingRoutes      @"routes"
#define kMappingRoute       @"route"
#define kMappingRouteName   @"name"
#define kHTTPMethod         @"method"

@implementation RKObjectManager (InExtensions)

- (void)loadMappingsFromDictionary:(NSDictionary *)mappingInfo
{
    NSParameterAssert(mappingInfo);
    
    NSDictionary* classMappings = [mappingInfo valueForKey:kMappingInfo];
    
    // Request Descriptors
	NSArray *requestMappings = [mappingInfo valueForKey:kRequestMapping];
	[requestMappings enumerateObjectsUsingBlock:^(NSDictionary* requestInfo, NSUInteger idx, BOOL *stop)
     {
         Class mapClass = NSClassFromString([requestInfo valueForKey:kMappingClass]);
         RKObjectMapping *requestMapping = [RKObjectMapping requestMappingForClass:mapClass mappingInfo:classMappings];
         NSAssert(requestMapping, @"Missing object mapping");

         NSString* httpMethod = [requestInfo objectForKey:kHTTPMethod];
         RKRequestMethod method = (httpMethod)? RKRequestMethodFromString(httpMethod) : RKRequestMethodAny;
         RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping
                                                                                        objectClass:mapClass
                                                                                        rootKeyPath:nil
                                                                                             method:method];
         [self addRequestDescriptor:requestDescriptor];
     }];
    
    // Response Descriptors
    NSArray* responseDescriptors = [mappingInfo valueForKey:kResponseMapping];
	[responseDescriptors enumerateObjectsUsingBlock:^(NSDictionary* responseInfo, NSUInteger idx, BOOL *stop)
     {
         // Class
         Class mapClass = NSClassFromString([responseInfo valueForKey:kMappingClass]);
         RKObjectMapping* objMapping = [RKObjectMapping responseMappingForClass:mapClass mappingInfo:classMappings];
         NSAssert(objMapping, @"Missing object mapping");
         
         // Status code range
         NSNumber* statusCodeClass = [responseInfo objectForKey:kStatusCode];
         NSIndexSet* statusCodes = (statusCodeClass)? RKStatusCodeIndexSetForClass([statusCodeClass integerValue])
                                                    : RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
         
         // Descriptor
         NSString* pathPattern = [responseInfo objectForKey:kPathPattern];
         NSString* keyPath = [responseInfo objectForKey:kKeyPath];
         NSString* httpMethod = [responseInfo objectForKey:kHTTPMethod];
         RKRequestMethod method = (httpMethod)? RKRequestMethodFromString(httpMethod) : RKRequestMethodAny;
         RKResponseDescriptor* descriptor = [RKResponseDescriptor responseDescriptorWithMapping:objMapping
                                                                                         method:method
                                                                                    pathPattern:pathPattern
                                                                                        keyPath:keyPath
                                                                                    statusCodes:statusCodes];
         [self addResponseDescriptor:descriptor];
     }];
    
    
    // Mapping routes
    RKRouter* router = [self router];
    NSArray* routes = [mappingInfo valueForKey:kMappingRoutes];
    [routes enumerateObjectsUsingBlock:^(NSDictionary *info, NSUInteger idx, BOOL *stop)
    {
        NSString* httpMethod = [info objectForKey:kHTTPMethod];
        NSString* routeName = [info objectForKey:kMappingRouteName];
        NSString* mapRoute = [info objectForKey:kMappingRoute];
        
        RKRoute* route = nil;
        if (routeName)
        {
            route = [RKRoute routeWithName:routeName
                               pathPattern:mapRoute
                                    method:RKRequestMethodFromString(httpMethod)];
            
        }
        else
        {
            Class mapClass = NSClassFromString([info objectForKey:kMappingClass]);
            RKRequestMethod requestMethod = (httpMethod)? RKRequestMethodFromString(httpMethod) : RKRequestMethodAny;
            
            route = [RKRoute routeWithClass:mapClass
                                pathPattern:mapRoute
                                     method:requestMethod];
            
        }
        
        
        NSParameterAssert(route);
        [[router routeSet] addRoute:route];
    }];
}


@end
