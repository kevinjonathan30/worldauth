//
//  TorchModule.mm
//  WorldAuthCore
//
//  Created by Kevin Jonathan on 2025/05/12.
//

#import <WorldAuthCoreML/DGMRModule.h>
#include <torch/csrc/jit/mobile/import.h>
#include <torch/csrc/jit/mobile/module.h>
#include <torch/script.h>

@implementation DGMRModule {
 @protected
  torch::jit::mobile::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
    self = [super init];
    if (self) {
        try {
            _impl = torch::jit::_load_for_mobile(filePath.UTF8String);
        } catch (const std::exception& exception) {
            NSLog(@"Error loading TorchScript model: %s", exception.what());
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
        // Validate input point count
        if (numPoints1 <= 0 || numPoints2 <= 0) {
            NSLog(@"Invalid number of points: numPoints1 = %d, numPoints2 = %d", numPoints1, numPoints2);
            return nil;
        }

        // Create tensors from input data
        at::Tensor tensor1 = torch::from_blob(pointCloud1, {1, numPoints1, 3}, at::kFloat).clone();
        at::Tensor tensor2 = torch::from_blob(pointCloud2, {1, numPoints2, 3}, at::kFloat).clone();

        // Validate tensor shapes
        if (tensor1.sizes() != std::vector<int64_t>{1, numPoints1, 3} ||
            tensor2.sizes() != std::vector<int64_t>{1, numPoints2, 3}) {
            NSLog(@"Input tensor shapes are incorrect: tensor1 = %@, tensor2 = %@", tensor1.sizes(), tensor2.sizes());
            return nil;
        }

        // Enable inference mode
        c10::InferenceMode guard;

        // Forward pass
        auto outputTensor = _impl.forward({tensor1, tensor2}).toTensor();

        // Validate output tensor shape
        if (outputTensor.sizes() != std::vector<int64_t>{1, 4, 4}) {
            NSLog(@"Unexpected output tensor shape: %@", outputTensor.sizes());
            return nil;
        }

        // Extract transformation matrix
        float* transformationMatrix = outputTensor.data_ptr<float>();
        if (!transformationMatrix) {
            NSLog(@"Failed to retrieve transformation matrix");
            return nil;
        }

        // Convert to NSArray<NSNumber*>
        NSMutableArray* results = [NSMutableArray arrayWithCapacity:16];
        for (int i = 0; i < 16; i++) {
            [results addObject:@(transformationMatrix[i])];
        }

        return [results copy];
    } catch (const std::exception& exception) {
        NSLog(@"Error during inference: %s", exception.what());
        return nil;
    }
}
@end
