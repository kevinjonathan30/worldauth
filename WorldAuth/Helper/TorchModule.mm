//
//  TorchModule.mm
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/04/29.
//

#import "TorchModule.h"
//#include <torch/csrc/jit/mobile/import.h>
//#include <torch/csrc/jit/mobile/module.h>
//#include <torch/script.h>
#import <Libtorch-Lite/Libtorch-Lite.h>

@implementation TorchModule {
 @protected
  torch::jit::mobile::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
  self = [super init];
  if (self) {
    try {
      _impl = torch::jit::_load_for_mobile(filePath.UTF8String);
    } catch (const std::exception& exception) {
      NSLog(@"Error loading model: %s", exception.what());
      return nil;
    }
  }
  return self;
}

- (NSArray<NSNumber*>*)registerPointCloud:(float*)pointCloud1
                            withNumPoints:(int)numPoints1
                           andPointCloud:(float*)pointCloud2
                            withNumPoints:(int)numPoints2 {
  try {
    // Convert input point clouds to tensors
    // Shape: [1, numPoints, 3] for each point cloud
    at::Tensor tensor1 = torch::from_blob(
        pointCloud1,
        {1, numPoints1, 3},
        at::kFloat
    );
    
    at::Tensor tensor2 = torch::from_blob(
        pointCloud2,
        {1, numPoints2, 3},
        at::kFloat
    );
    
    // Run the model in inference mode
    c10::InferenceMode guard;
    
    // Forward pass with both tensors
    auto outputTensor = _impl.forward({tensor1, tensor2}).toTensor();
    
    // Get the transformation matrix (4x4)
    // Output shape should be [B, 4, 4] where B is batch size (1)
    float* transformationMatrix = outputTensor.data_ptr<float>();
    
    if (!transformationMatrix) {
      NSLog(@"Failed to get transformation matrix data");
      return nil;
    }
    
    // Convert to NSArray of NSNumbers
    // Assuming the transformation matrix is 4x4 = 16 elements
    NSMutableArray* results = [[NSMutableArray alloc] init];
    for (int i = 0; i < 16; i++) {
      [results addObject:@(transformationMatrix[i])];
    }
    
    return [results copy];
    
  } catch (const std::exception& exception) {
    NSLog(@"Error during inference: %s", exception.what());
  }
  return nil;
}

@end
