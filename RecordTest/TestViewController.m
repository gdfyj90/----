//
//  TestViewController.m
//  RecordTest
//
//  Created by fyj on 14-2-11.
//  Copyright (c) 2014年 fyj. All rights reserved.
//

#import "TestViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "QiniuSimpleUploader.h"
#import "QiniuPutPolicy.h"


#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

static NSString *QiniuAccessKey = @"lF9qRIYM8__M6wgkGpg6aCK7xU2O-zZM4ZCD0d_d";
static NSString *QiniuSecretKey = @"PbmAsKktShHu3-aWe1KoSXxsiVpS627zL_FcBntw";
static NSString *QiniuBucketName = @"https://portal.qiniu.com/bucket/index?bucket=fyj1990";

@interface TestViewController ()


@end

@implementation TestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    volume=[[UIImageView alloc]initWithFrame:CGRectMake(112.5f, 50, 75, 111)];
    
    UIButton *record=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    record.frame=CGRectMake(50, 300, 50, 50);
    [record setTitle:@"录音" forState:UIControlStateNormal];
    [record addTarget:self action:@selector(recording:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *play=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    play.frame=CGRectMake(120, 300, 50, 50);
    [play setTitle:@"播放" forState:UIControlStateNormal];
    [play addTarget:self action:@selector(playing) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *upload=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    upload.frame=CGRectMake(190, 300, 50, 50);
    [upload setTitle:@"上传" forState:UIControlStateNormal];
    [upload addTarget:self action:@selector(uploadContent) forControlEvents:UIControlEventTouchUpInside];
    
    lab=[[UILabel alloc]initWithFrame:CGRectMake(50, 370, 200, 30)];
    lab.text=@"还没录音";
    
    [self.view addSubview:volume];
    [self.view addSubview:record];
    [self.view addSubview:play];
    [self.view addSubview:upload];
    [self.view addSubview:lab];
    isStart=NO;
    
    [self ready];
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

-(void)ready
{
    NSError *error;
    
    NSDictionary* recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                   [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                   [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                   [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithInt:AVAudioQualityHigh], AVEncoderAudioQualityKey,
                                   nil];
    
    
    strUrl = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    strUrl=[strUrl stringByAppendingString:@"/abc.MP3"];
    recordedTmpFile = [NSURL fileURLWithPath:strUrl];
    
    NSLog(@"路径: %@",recordedTmpFile);
    
    recorder = [[AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error];
    recorder.meteringEnabled = YES;
    [recorder setDelegate:self];
}


-(void)recording:(id)sender
{
    NSError *error;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if(session == nil){
        NSLog(@"Error creating session: %@", [error description]);
    }
    else{
        [session setActive:YES error:nil];
    }
    
    if (isStart) {
        isStart=NO;
        
        [recorder stop];
        recorder=nil;
        [timer invalidate];
        
        end=[NSDate date];
        NSTimeInterval time;
        time=[end timeIntervalSinceDate:start];
        
        [sender setTitle:@"录音" forState:UIControlStateNormal];
        
        
        NSString *str=[NSString stringWithFormat:@"录音时间为%.2f秒",time];
        lab.text=str;
        
    }
    else{
        isStart=YES;
        
        [recorder prepareToRecord];
        [recorder record];
        
        start=[NSDate date];
        //NSLog(@"date:%@",start);
        
        [sender setTitle:@"停止" forState:UIControlStateNormal];
        lab.text=@"正在录音";
        
        timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(detectionVoice) userInfo:nil repeats:YES];
    }
    
}

-(void)playing
{
    NSError *error;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if(session == nil){
        NSLog(@"Error creating session: %@", [error description]);
    }
    else{
        [session setActive:YES error:nil];
    }
    
    AVAudioPlayer * avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedTmpFile error:&error];
    [avPlayer prepareToPlay];
    [avPlayer play];
    
}


//借鉴网上的，如果用代码画图感觉挺费力
- (void)detectionVoice
{
    [recorder updateMeters];//刷新音量数据
    //获取音量的平均值  [recorder averagePowerForChannel:0];
    //音量的最大值  [recorder peakPowerForChannel:0];
    
    double lowPassResults = pow(10, (0.05 * [recorder peakPowerForChannel:0]));
    NSLog(@"%lf",lowPassResults);
    //最大50  0
    //图片 小-》大
    if (0<lowPassResults<=0.06) {
        [volume setImage:[UIImage imageNamed:@"record_animate_01.png"]];
    }else if (0.06<lowPassResults<=0.13) {
        [volume setImage:[UIImage imageNamed:@"record_animate_02.png"]];
    }else if (0.13<lowPassResults<=0.20) {
        [volume setImage:[UIImage imageNamed:@"record_animate_03.png"]];
    }else if (0.20<lowPassResults<=0.27) {
        [volume setImage:[UIImage imageNamed:@"record_animate_04.png"]];
    }else if (0.27<lowPassResults<=0.34) {
        [volume setImage:[UIImage imageNamed:@"record_animate_05.png"]];
    }else if (0.34<lowPassResults<=0.41) {
        [volume setImage:[UIImage imageNamed:@"record_animate_06.png"]];
    }else if (0.41<lowPassResults<=0.48) {
        [volume setImage:[UIImage imageNamed:@"record_animate_07.png"]];
    }else if (0.48<lowPassResults<=0.55) {
        [volume setImage:[UIImage imageNamed:@"record_animate_08.png"]];
    }else if (0.55<lowPassResults<=0.62) {
        [volume setImage:[UIImage imageNamed:@"record_animate_09.png"]];
    }else if (0.62<lowPassResults<=0.69) {
        [volume setImage:[UIImage imageNamed:@"record_animate_10.png"]];
    }else if (0.69<lowPassResults<=0.76) {
        [volume setImage:[UIImage imageNamed:@"record_animate_11.png"]];
    }else if (0.76<lowPassResults<=0.83) {
        [volume setImage:[UIImage imageNamed:@"record_animate_12.png"]];
    }else if (0.83<lowPassResults<=0.9) {
        [volume setImage:[UIImage imageNamed:@"record_animate_13.png"]];
    }else {
        [volume setImage:[UIImage imageNamed:@"record_animate_14.png"]];
    }
}


-(void)uploadContent
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    
    NSString *key = [NSString stringWithFormat:@"%@%@", timeDesc, @".mp3"];
    NSString *filePath = [strUrl stringByAppendingPathComponent:key];
    
    NSLog(@"file:%@",filePath);
    [self uploadFile:strUrl bucket:QiniuBucketName key:key];
}

- (void)uploadFile:(NSString *)filePath bucket:(NSString *)bucket key:(NSString *)key {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:filePath]) {
        
        if (uploader) {
            uploader=nil;
        }
        uploader = [QiniuSimpleUploader uploaderWithToken:[self tokenWithScope:bucket]];
        uploader.delegate = self;
        
        [uploader uploadFile:filePath key:key extra:nil];
    }
}

- (NSString *)tokenWithScope:(NSString *)scope
{
    QiniuPutPolicy *policy = [QiniuPutPolicy new];
    policy.scope = scope;
    
    return [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
}



- (void)uploadSucceeded:(NSString *)filePath ret:(NSDictionary *)ret
{
    NSLog(@"%@",ret);
}

- (void)uploadFailed:(NSString *)filePath error:(NSError *)error
{
    NSLog(@"%@",error);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
