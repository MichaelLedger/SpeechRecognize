//
//  iOSSpeechViewController.m
//  MyDemo
//
//  Created by MTX on 2016/12/9.
//  Copyright © 2016年 MTX. All rights reserved.
//

#define LoadingText @"正在录音。。。"
#import "iOSSpeechViewController.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
@interface iOSSpeechViewController () <SFSpeechRecognizerDelegate>
@property (nonatomic,strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic,strong) AVAudioEngine *audioEngine;
@property (nonatomic,strong) SFSpeechRecognitionTask *recognitionTask;
@property (weak, nonatomic) IBOutlet UILabel *resultStringLable;
@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@end

@implementation iOSSpeechViewController

#pragma mark - lifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    _recordButton.enabled = NO;
    // Do any additional setup after loading the view from its nib.
}


- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;
    [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    weakSelf.recordButton.enabled = NO;
                    [weakSelf.recordButton setTitle:@"语音识别未授权" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    weakSelf.recordButton.enabled = NO;
                    [weakSelf.recordButton setTitle:@"用户未授权使用语音识别" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    weakSelf.recordButton.enabled = NO;
                    [weakSelf.recordButton setTitle:@"语音识别在这台设备上受到限制" forState:UIControlStateDisabled];
                    
                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    weakSelf.recordButton.enabled = YES;
                    [weakSelf.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
                    break;
                    
                default:
                    break;
            }
            
        });
    }];
}

#pragma mark - action
/**
 识别本地音频文件
 
 @param sender <#sender description#>
 */
- (IBAction)recognizeLocalAudioFile:(UIButton *)sender {
    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    SFSpeechRecognizer *localRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
    NSURL *url =[[NSBundle mainBundle] URLForResource:@"录音.m4a" withExtension:nil];
    if (!url) return;
    SFSpeechURLRecognitionRequest *res =[[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    __weak typeof(self) weakSelf = self;
    [localRecognizer recognitionTaskWithRequest:res resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"语音识别解析失败,%@",error);
        }
        else
        {
            weakSelf.resultStringLable.text = result.bestTranscription.formattedString;
        }
    }];
    
}

- (IBAction)recordButtonClicked:(UIButton *)sender {
    if (self.audioEngine.isRunning) {
        [self endRecording];
        [self.recordButton setTitle:@"正在停止" forState:UIControlStateDisabled];
        
    }
    else{
        [self startRecording];
        [self.recordButton setTitle:@"停止录音" forState:UIControlStateNormal];
        
    }
}

- (void)endRecording{
    [self.audioEngine stop];
    if (_recognitionRequest) {
        [_recognitionRequest endAudio];
    }
    
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    self.recordButton.enabled = NO;
    
    if ([self.resultStringLable.text isEqualToString:LoadingText]) {
        self.resultStringLable.text = @"";
    }
}
- (void)startRecording{
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {
            strongSelf.resultStringLable.text = result.bestTranscription.formattedString;
            isFinal = result.isFinal;
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            strongSelf.recognitionTask = nil;
            strongSelf.recognitionRequest = nil;
            strongSelf.recordButton.enabled = YES;
            [strongSelf.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
        }
        
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
    self.resultStringLable.text = LoadingText;
}
#pragma mark - property
- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
//        // 获取当前设备支持语言数组
//        NSArray<NSString *> *arr = [NSLocale availableLocaleIdentifiers];
//        NSMutableArray *availableLocales = [NSMutableArray arrayWithCapacity:arr.count];
//        [arr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//            [dict setValue:obj forKey:@"identifier"];
//            NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:obj];
//
//            NSLocale *chineseLocal = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
//            NSString *chineseLanguage = [chineseLocal displayNameForKey:NSLocaleIdentifier value:obj];
//            [dict setValue:chineseLanguage forKey:@"chineseDes"];
//
//            NSLocale *englishLocal = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
//            NSString *englishLanguage = [englishLocal displayNameForKey:NSLocaleIdentifier value:obj];
//            [dict setValue:englishLanguage forKey:@"englishDes"];
//
//            NSString *currencySymbol = local.currencySymbol;
//            [dict setValue:currencySymbol forKey:@"currencySymbol"];
//
//            NSString *countryCode = local.countryCode;
//            [dict setValue:countryCode forKey:@"countryCode"];
//
//            [availableLocales addObject:dict];
//        }];
//        NSLog(@"availableLocaleIdentifiers:\n%@", availableLocales);
        
        // 获取当前设备支持语言数组
        NSArray<NSString *> *arr = [NSLocale availableLocaleIdentifiers];
        [arr enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:obj];
            
            NSLocale *chineseLocal = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
            NSString *chineseLanguage = [chineseLocal displayNameForKey:NSLocaleIdentifier value:obj];
            
            NSLocale *englishLocal = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
            NSString *englishLanguage = [englishLocal displayNameForKey:NSLocaleIdentifier value:obj];
            
            NSString *currencySymbol = local.currencySymbol;
            
            NSString *countryCode = local.countryCode;
            
            NSLog(@"%@-%@-%@-%@-%@", obj, chineseLanguage, englishLanguage, currencySymbol, countryCode);
        }];
        
        /*
         Cannot make recognizer for ta-IN. Supported locale identifiers are {(
             "nl-NL",
             "es-MX",
             "fr-FR",
             "zh-TW",
             "it-IT",
             "vi-VN",
             "fr-CH",
             "es-CL",
             "en-ZA",
             "ko-KR",
             "ca-ES",
             "ro-RO",
             "en-PH",
             "es-419",
             "en-CA",
             "en-SG",
             "en-IN",
             "en-NZ",
             "it-CH",
             "fr-CA",
             "hi-IN",
             "da-DK",
             "de-AT",
             "pt-BR",
             "yue-CN",
             "zh-CN",
             "sv-SE",
             "hi-IN-translit",
             "es-ES",
             "ar-SA",
             "hu-HU",
             "fr-BE",
             "en-GB",
             "ja-JP",
             "zh-HK",
             "fi-FI",
             "tr-TR",
             "nb-NO",
             "en-ID",
             "en-SA",
             "pl-PL",
             "ms-MY",
             "cs-CZ",
             "el-GR",
             "id-ID",
             "hr-HR",
             "en-AE",
             "he-IL",
             "ru-RU",
             "wuu-CN",
             "de-DE",
             "de-CH",
             "en-AU",
             "nl-BE",
             "th-TH",
             "pt-PT",
             "sk-SK",
             "en-US",
             "en-IE",
             "es-CO",
             "hi-Latn",
             "uk-UA",
             "es-US"
         )}
         */
        
        //语音识别对象设置语言，这里设置的是中文
        NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh-CN"];
        
        _speechRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}
#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        self.recordButton.enabled = YES;
        [self.recordButton setTitle:@"开始录音" forState:UIControlStateNormal];
    }
    else{
        self.recordButton.enabled = NO;
        [self.recordButton setTitle:@"语音识别不可用" forState:UIControlStateDisabled];
    }
}


@end

