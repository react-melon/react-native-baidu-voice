//
//  RNBaiduVoice.m
//  reactNativeBaiduVoice
//
//  Created by baidu on 15/11/9.
//  Copyright © 2015年 Facebook. All rights reserved.
//

#import "RNBaiduVoice.h"
#import "RCTConvert.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import "BDVRRawDataRecognizer.h"
#import "BDVRFileRecognizer.h"
#import <AVFoundation/AVFoundation.h>


NSString *const ApiKey = @"iHpZ99Q8cCvHAN3yx6j4yxwE";
NSString *const SecretKey = @"2d609c05305048034d031c0fea1862df";


@implementation RNBaiduVoice

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(startRecognition)
{
  [[BDVoiceRecognitionClient sharedInstance] setApiKey:ApiKey withSecretKey:SecretKey];
  
  int startStatus = [[BDVoiceRecognitionClient sharedInstance] startVoiceRecognition:self];

  [self.bridge.eventDispatcher sendAppEventWithName:@"RecognitionEvent" body:@{
    @"type": @"start",
    @"status": [NSString stringWithFormat:@"%d", startStatus]
  }];
}

RCT_EXPORT_METHOD(cancelRecognition)
{
  //停止 BDVRClient 的识别过程，该方法会释放相应的资源，并向接受识别结果接口中发送用户取消通知。
  [[BDVoiceRecognitionClient sharedInstance] stopVoiceRecognition];
  
  NSLog(@"hello");
}

RCT_EXPORT_METHOD(finishRecognition)
{
  // 结束语音识别，录音完成，此后可以放心地等待结果返回和状态通知，不需要添加额外代码。
  [[BDVoiceRecognitionClient sharedInstance] speakFinish];
  
  NSLog(@"stop");
}


#pragma mark - MVoiceRecognitionClientDelegate

- (void)VoiceRecognitionClientErrorStatus:(int) aStatus subStatus:(int)aSubStatus
{
  NSLog(@"%d", aStatus);
}

- (void)VoiceRecognitionClientWorkStatus:(int)aStatus obj:(id)aObj
{
  switch (aStatus)
  {
    case EVoiceRecognitionClientWorkStatusFlushData:
    {
      // 该状态值表示服务器返回了中间结果，如果想要将中间结果展示给用户（形成连续上屏的效果），
      // 可以利用与该状态同时返回的数据，每当接到新的该类消息应当清空显示区域的文字以免重复
      NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
      [tmpString appendFormat:@"%@",[aObj objectAtIndex:0]];
      NSLog(@"result: %@", tmpString);
      [self.bridge.eventDispatcher sendAppEventWithName:@"RecognitionEvent" body:@{
        @"type": @"finish",
        @"result": tmpString
      }];
      break;
    }
    case EVoiceRecognitionClientWorkStatusFinish:
    {
      // 该状态值表示语音识别服务器返回了最终结果，结果以数组的形式保存在 aObj 对象中
      // 接受到该消息时应当清空显示区域的文字以免重复
      if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput)
      {
        NSMutableArray *resultData = (NSMutableArray *)aObj;
        NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
        // 获取识别候选词列表
        for (int i=0; i<[resultData count]; i++)
        {
          [tmpString appendFormat:@"%@\r\n",[resultData objectAtIndex:i]];
        }
        NSLog(@"result: %@", tmpString);
//        [tmpString release];
        [self.bridge.eventDispatcher sendAppEventWithName:@"RecognitionEvent" body:@{
          @"type": @"finish",
          @"result": tmpString
        }];
      }
      else
      {
        NSMutableString *sentenceString = [[NSMutableString alloc] initWithString:@""];
        for (NSArray *result in aObj)// 此时 aObj 是 array，result 也是 array
        {
          // 取每条候选结果的第一条，进行组合
          // result 的元素是 dictionary，对应一个候选词和对应的可信度
          NSDictionary *dic = [result objectAtIndex:0];
          NSString *candidateWord = [[dic allKeys] objectAtIndex:0];
          [sentenceString appendString:candidateWord];
        }
        NSLog(@"result: %@", sentenceString);
        [self.bridge.eventDispatcher sendAppEventWithName:@"RecognitionEvent" body:@{
          @"type": @"finish",
          @"result": sentenceString
        }];
      }
      break;
    }
    case EVoiceRecognitionClientWorkStatusReceiveData:
    {
      // 此状态只在输入模式下发生，表示语音识别正确返回结果，每个子句会通知一次（全量，
      // 即第二次收到该消息时所携带的结果包含第一句的识别结果），应用程序可以
      // 逐句显示。配合连续上屏的中间结果，可以进一步提升语音输入的体验
      NSMutableString *sentenceString = [[NSMutableString alloc] initWithString:@""];
      for (NSArray *result in aObj)// 此时 aObj 是 array，result 也是 array
      {
        // 取每条候选结果的第一条，进行组合
        // result 的元素是 dictionary，对应一个候选词和对应的可信度
        NSDictionary *dic = [result objectAtIndex:0];
        NSString *candidateWord = [[dic allKeys] objectAtIndex:0];
        [sentenceString appendString:candidateWord];
      }
      NSLog(@"result: %@", sentenceString);
      break;
    }
    case EVoiceRecognitionClientWorkStatusNewRecordData:
    {
      // 有音频数据输出，音频数据格式为 PCM，在有 WiFi 连接的条件下为 16k16bit，非 WiFi
      // 为 8k16bit
      break;
    }
    case EVoiceRecognitionClientWorkStatusEnd:
    {
      // 用户说话完成，但服务器尚未返回结果
      break;
    }
    case EVoiceRecognitionClientWorkStatusCancel:
    {
      // 用户主动取消
      break;
    }
    case EVoiceRecognitionClientWorkStatusError:
    {
      // 错误状态
      break;
    }
    case EVoiceRecognitionClientWorkPlayStartTone:
    case EVoiceRecognitionClientWorkPlayStartToneFinish:
    case EVoiceRecognitionClientWorkStatusStartWorkIng:
    case EVoiceRecognitionClientWorkStatusStart:
    case EVoiceRecognitionClientWorkPlayEndToneFinish:
    case EVoiceRecognitionClientWorkPlayEndTone:
//    case EVoiceRecognitionClientWorkStatusEndAndToTackNetWork:
    {
      // 其他中间状态
      break;
    }
  }
}


@end

