//
//  TestViewController.h
//  RecordTest
//
//  Created by fyj on 14-2-11.
//  Copyright (c) 2014年 fyj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "QiniuUploadDelegate.h"
#import "QiniuSimpleUploader.h"

@interface TestViewController : UIViewController<AVAudioRecorderDelegate,QiniuUploadDelegate>
{
    BOOL isStart;//判断是否开始录音
    UIImageView *volume;
    UILabel *lab;
    
    NSURL *recordedTmpFile;
    AVAudioRecorder *recorder;
    
    NSString *strUrl;
    NSDate *start;
    NSDate *end;
    
    NSTimer *timer;
    
    QiniuSimpleUploader *uploader;
}
@end
