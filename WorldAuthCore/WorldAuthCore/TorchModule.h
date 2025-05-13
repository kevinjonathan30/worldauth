//
//  TorchModule.h
//  WorldAuthCore
//
//  Created by Kevin Jonathan on 2025/05/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TorchModule : NSObject

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath
    NS_SWIFT_NAME(init(fileAtPath:))NS_DESIGNATED_INITIALIZER;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

// Method to register two point clouds and return the transformation matrix
- (nullable NSArray<NSNumber*>*)registerPointCloud:(float*)pointCloud1
                                      withNumPoints:(int)numPoints1
                                     andPointCloud:(float*)pointCloud2
                                      withNumPoints:(int)numPoints2
    NS_SWIFT_NAME(registerPointCloud(points1:numPoints1:points2:numPoints2:));

@end

NS_ASSUME_NONNULL_END
