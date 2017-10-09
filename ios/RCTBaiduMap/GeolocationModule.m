//
//  GoelocationModule.m
//  RCTBaiduMap
//
//  Created by lovebing on 2016/10/28.
//  Copyright © 2016年 lovebing.org. All rights reserved.
//

#import "GeolocationModule.h"


@implementation GeolocationModule {
  BMKPointAnnotation* _annotation;
}

@synthesize bridge = _bridge;

static BMKGeoCodeSearch *geoCodeSearch;
static BMKLocationService *locationService;

RCT_EXPORT_MODULE(BaiduGeolocationModule);

RCT_EXPORT_METHOD(getBaiduCoorFromGPSCoor:(double)lat lng:(double)lng
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  NSLog(@"getBaiduCoorFromGPSCoor");
  CLLocationCoordinate2D baiduCoor = [self getBaiduCoor:lat lng:lng];
  
  NSDictionary* coor = @{
                         @"latitude": @(baiduCoor.latitude),
                         @"longitude": @(baiduCoor.longitude)
                         };
  
  resolve(coor);
}

RCT_EXPORT_METHOD(geocode:(NSString *)city addr:(NSString *)addr) {
  
  [self getGeocodesearch].delegate = self;
  
  BMKGeoCodeSearchOption *geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc]init];
  
  geoCodeSearchOption.city= city;
  geoCodeSearchOption.address = addr;
  
  BOOL flag = [[self getGeocodesearch] geoCode:geoCodeSearchOption];
  
  if(flag) {
    NSLog(@"geo检索发送成功");
  } else{
    NSLog(@"geo检索发送失败");
  }
}

RCT_EXPORT_METHOD(reverseGeoCode:(double)lat lng:(double)lng) {
  
  [self getGeocodesearch].delegate = self;
  CLLocationCoordinate2D baiduCoor = CLLocationCoordinate2DMake(lat, lng);
  
  CLLocationCoordinate2D pt = (CLLocationCoordinate2D){baiduCoor.latitude, baiduCoor.longitude};
  
  BMKReverseGeoCodeOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
  reverseGeoCodeSearchOption.reverseGeoPoint = pt;
  
  BOOL flag = [[self getGeocodesearch] reverseGeoCode:reverseGeoCodeSearchOption];
  
  if(flag) {
    NSLog(@"逆向地理编码发送成功");
  }
  //[reverseGeoCodeSearchOption release];
}

RCT_EXPORT_METHOD(reverseGeoCodeGPS:(double)lat lng:(double)lng) {
  
  [self getGeocodesearch].delegate = self;
  CLLocationCoordinate2D baiduCoor = [self getBaiduCoor:lat lng:lng];
  
  CLLocationCoordinate2D pt = (CLLocationCoordinate2D){baiduCoor.latitude, baiduCoor.longitude};
  
  BMKReverseGeoCodeOption *reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
  reverseGeoCodeSearchOption.reverseGeoPoint = pt;
  
  BOOL flag = [[self getGeocodesearch] reverseGeoCode:reverseGeoCodeSearchOption];
  
  if(flag) {
    NSLog(@"逆向地理编码发送成功");
  }
  //[reverseGeoCodeSearchOption release];
}

-(BMKGeoCodeSearch *)getGeocodesearch{
  if(geoCodeSearch == nil) {
    geoCodeSearch = [[BMKGeoCodeSearch alloc]init];
  }
  return geoCodeSearch;
}

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
  NSMutableDictionary *body = [self getEmptyBody];
  
  if (error == BMK_SEARCH_NO_ERROR) {
    NSString *latitude = [NSString stringWithFormat:@"%f", result.location.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", result.location.longitude];
    body[@"latitude"] = latitude;
    body[@"longitude"] = longitude;
  }
  else {
    body[@"errcode"] = [NSString stringWithFormat:@"%d", error];
    body[@"errmsg"] = [self getSearchErrorInfo:error];
  }
  [self sendEvent:@"onGetGeoCodeResult" body:body];
  
}
-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result
                        errorCode:(BMKSearchErrorCode)error {
  
  NSMutableDictionary *body = [self getEmptyBody];
  
  if (error == BMK_SEARCH_NO_ERROR) {
    // 使用离线地图之前，需要先初始化百度地图
    [[BMKMapView alloc] initWithFrame:CGRectZero];
    // 离线地图api或去citycode
    BMKOfflineMap *offlineMap = [[BMKOfflineMap alloc] init];
    NSArray *cityCodeArr = [offlineMap searchCity:result.addressDetail.city];
    if (cityCodeArr.count) {
      BMKOLSearchRecord *searchRecord = cityCodeArr.firstObject;
      body[@"cityCode"] = @(searchRecord.cityID).stringValue;
      searchRecord = nil;
      
    }
    cityCodeArr = nil;
    offlineMap = nil;
    
    body[@"latitude"] = [NSString stringWithFormat:@"%f", result.location.latitude];
    body[@"longitude"] = [NSString stringWithFormat:@"%f", result.location.longitude];
    body[@"address"] = result.address;
    body[@"province"] = result.addressDetail.province;
    body[@"city"] = result.addressDetail.city;
    body[@"district"] = result.addressDetail.district;
    body[@"streetName"] = result.addressDetail.streetName;
    body[@"streetNumber"] = result.addressDetail.streetNumber;
  }
  else {
    body[@"errcode"] = [NSString stringWithFormat:@"%d", error];
    body[@"errmsg"] = [self getSearchErrorInfo:error];
  }
  [self sendEvent:@"onGetReverseGeoCodeResult" body:body];
  
  geoCodeSearch.delegate = nil;
}
-(NSString *)getSearchErrorInfo:(BMKSearchErrorCode)error {
  NSString *errormsg = @"Unknown error";
  switch (error) {
    case BMK_SEARCH_AMBIGUOUS_KEYWORD:
      errormsg = @"AMBIGUOUS KEYWORD";
      break;
    case BMK_SEARCH_AMBIGUOUS_ROURE_ADDR:
      errormsg = @"The search address is ambiguous";
      break;
    case BMK_SEARCH_NOT_SUPPORT_BUS:
      errormsg = @"The search address is ambiguous";
      break;
    case BMK_SEARCH_NOT_SUPPORT_BUS_2CITY:
      errormsg = @"Does not support cross-city bus";
      break;
    case BMK_SEARCH_RESULT_NOT_FOUND:
      errormsg = @"No search results found";
      break;
    case BMK_SEARCH_ST_EN_TOO_NEAR:
      errormsg = @"The end is too close";
      break;
    case BMK_SEARCH_KEY_ERROR:
      errormsg = @"key error";
      break;
    case BMK_SEARCH_NETWOKR_ERROR:
      errormsg = @"Network connection error";
      break;
    case BMK_SEARCH_NETWOKR_TIMEOUT:
      errormsg = @"Network connection timed out";
      break;
    case BMK_SEARCH_PERMISSION_UNFINISHED:
      errormsg = @"If the authentication has not yet been completed, please try again after authentication";
      break;
    case BMK_SEARCH_INDOOR_ID_ERROR:
      errormsg = @"Indoor ID is wrong";
      break;
    case BMK_SEARCH_FLOOR_ERROR:
      errormsg = @"Interior map search floor error";
      break;
    default:
      break;
  }
  return errormsg;
}

-(CLLocationCoordinate2D)getBaiduCoor:(double)lat lng:(double)lng {
  CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(lat, lng);
  NSDictionary* testdic = BMKConvertBaiduCoorFrom(coor,BMK_COORDTYPE_COMMON);
  testdic = BMKConvertBaiduCoorFrom(coor,BMK_COORDTYPE_GPS);
  CLLocationCoordinate2D baiduCoor = BMKCoorDictionaryDecode(testdic);
  
  return baiduCoor;
}


@end
