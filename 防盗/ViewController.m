//
//  ViewController.m
//  防盗
//
//  Created by Tempo on 16/10/24.
//  Copyright © 2016年 Tempo. All rights reserved.
//

#import "ViewController.h"
#import "AccManager.h"
#import <mach/mach_time.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
BOOL kStarApp;

float accelero_rotation[3][3];

static inline float sign(float value)
{
    float result = 1.0;
    if(value < 0)
        result = -1.0;
    
    return result;
}

@interface ViewController ()<AVAudioPlayerDelegate>
{

    NSTimer *_myTimer;
    CGFloat timeValue;
    NSInteger timeValue_1;
    NSInteger timeValue_2;
    BOOL    accModeEnabled;
    BOOL    accModeReady;
    BOOL    kongzhiMode;
    SystemSoundID myAlertSound;
    AVAudioPlayer *player;
    
    MPVolumeView *volumeView;
    UISlider* volumeViewSlider;
    
    CGFloat minGanyingValue,maxGanyingValue;//感应值
    NSInteger denghouTime;//等候时间
    
    
}
@property (weak, nonatomic) IBOutlet UILabel *timeLabel_2;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel_1;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *starOnBut;
@property (weak, nonatomic) IBOutlet UIButton *starOffBut;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;

@property (weak, nonatomic) IBOutlet UILabel *valumLabel;
@property (weak, nonatomic) IBOutlet UIButton *kekongMode;
@property (weak, nonatomic) IBOutlet UIButton *feikongMode;
@property (weak, nonatomic) IBOutlet UITextField *ganyingTextView;
@property (weak, nonatomic) IBOutlet UITextField *denghouTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSString *path = [[NSBundle mainBundle]pathForResource:@"fd.mp3" ofType:nil];
    NSURL *url = [NSURL fileURLWithPath:path];
    player = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
    player.numberOfLoops = 100;
    [player prepareToPlay];
    
    kongzhiMode = NO;//默认为非控模式
    minGanyingValue = -0.9;
    maxGanyingValue = 0.9;
    _ganyingTextView.text = [NSString stringWithFormat:@"%.3f ~ %.3f",minGanyingValue,maxGanyingValue];
    denghouTime = 8;
    _denghouTextView.text = [NSString stringWithFormat:@"%ld",(long)denghouTime];
    
    

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
   
    [self.view endEditing:YES];

}

- (void)awakeFromNib{

    CMMotionManager *motionManager = [[AccManager shareManager]motionManager];
    if (motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1) {
        motionManager.accelerometerUpdateInterval = 1.0 / 40;
        [motionManager startAccelerometerUpdates];
       
    }else if (motionManager.deviceMotionAvailable == 1) {
        motionManager.deviceMotionUpdateInterval = 1.0 / 40;
        [motionManager startDeviceMotionUpdates];
    }else {
        accModeEnabled = FALSE;
        
    }
    
    [self setAcceleroRotationWithPhi:0.0 withTheta:0.0 withPsi:0.0];
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)(1.0 / 40) target:self selector:@selector(motionDataHandler) userInfo:nil repeats:YES];
}
- (IBAction)starOn:(UIButton *)sender {
    
    _myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(fdAction) userInfo:Nil repeats:YES];
    _starOnBut.enabled = NO;
//    [_starOnBut setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    _starOnBut.backgroundColor = [UIColor grayColor];
    _starOffBut.backgroundColor = [UIColor whiteColor];

    kStarApp = YES;

}

- (void)fdAction{

    if (timeValue < 10) {
        _timeLabel.text = [NSString stringWithFormat:@"0%ld",(long)timeValue];
    }else if (timeValue >= 10 && timeValue < 60){
    
        _timeLabel.text = [NSString stringWithFormat:@"%ld",(long)timeValue];
    }else if(timeValue == 60) {
        timeValue = 0;
        _timeLabel.text = [NSString stringWithFormat:@"0%ld",(long)timeValue];
        timeValue_1 ++;
    }
    
    
    if (timeValue_1 < 10) {
        _timeLabel_1.text = [NSString stringWithFormat:@"0%ld:",timeValue_1];
    }else if (timeValue_1 > 10 && timeValue_1 < 60){
        
        _timeLabel_1.text = [NSString stringWithFormat:@"%ld:",timeValue_1];
    }else if (timeValue_1 == 60){
        timeValue_1 = 0;
        _timeLabel_1.text = [NSString stringWithFormat:@"0%ld:",timeValue_1];
        timeValue_2 ++;
    }
    
    if (timeValue_2 < 10) {
        _timeLabel_2.text = [NSString stringWithFormat:@"0%ld:",timeValue_2];
    }else if (timeValue_2 > 10 && timeValue_2 < 60){
        
        _timeLabel_2.text = [NSString stringWithFormat:@"%ld:",timeValue_2];
    }else if (timeValue_2 == 60){
        timeValue_2 = 0;
        _timeLabel_2.text = [NSString stringWithFormat:@"0%ld:",timeValue_1];
    }
   
    timeValue += 0.5;
    
    CMMotionManager *motionManager = [[AccManager shareManager] motionManager];
    CMAcceleration current_acceleration;
    float phi, theta;
    
    //Get ACCELERO values－－－－加速度（值）
    if(motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1){
        //Only accelerometer (iphone 3GS)
        current_acceleration.x = motionManager.accelerometerData.acceleration.x;
        current_acceleration.y = motionManager.accelerometerData.acceleration.y;
        current_acceleration.z = motionManager.accelerometerData.acceleration.z;
    } else if (motionManager.deviceMotionAvailable == 1){
        //Accelerometer + gyro (iphone 4)
        current_acceleration.x = motionManager.deviceMotion.gravity.x + motionManager.deviceMotion.userAcceleration.x;
        current_acceleration.y = motionManager.deviceMotion.gravity.y + motionManager.deviceMotion.userAcceleration.y;
        current_acceleration.z = motionManager.deviceMotion.gravity.z + motionManager.deviceMotion.userAcceleration.z;
        
    }
    
    
    
    NSLog(@"%f",current_acceleration.z);
    if (current_acceleration.z > minGanyingValue && current_acceleration.z < maxGanyingValue) {
        NSLog(@"有人偷手机");
        if (timeValue > denghouTime) {
            [player play];
        }
    
    }else{
    
        if (kongzhiMode == YES) {
            [player pause];
        }
    }
    
    if ([player isPlaying]) {
        //始终保持音量最大
        volumeView = [[MPVolumeView alloc] init];
        volumeViewSlider = nil;
        for (UIView *view in [volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                volumeViewSlider = (UISlider*)view;
                break;
            }
        }
        [volumeViewSlider setValue:_sliderView.value animated:NO];
        [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    theta = atan2f(current_acceleration.x,sqrtf(current_acceleration.y*current_acceleration.y+current_acceleration.z*current_acceleration.z));
    phi = -atan2f(current_acceleration.y,sqrtf(current_acceleration.x*current_acceleration.x+current_acceleration.z*current_acceleration.z));
    
    [self setAcceleroRotationWithPhi:phi withTheta:theta withPsi:0];
    
}

- (void) setAcceleroRotationWithPhi:(float)phi withTheta:(float)theta withPsi:(float)psi
{
    accelero_rotation[0][0] = cosf(psi)*cosf(theta);
    accelero_rotation[0][1] = -sinf(psi)*cosf(phi) + cosf(psi)*sinf(theta)*sinf(phi);
    accelero_rotation[0][2] = sinf(psi)*sinf(phi) + cosf(psi)*sinf(theta)*cosf(phi);
    accelero_rotation[1][0] = sinf(psi)*cosf(theta);
    accelero_rotation[1][1] = cosf(psi)*cosf(phi) + sinf(psi)*sinf(theta)*sinf(phi);
    accelero_rotation[1][2] = -cosf(psi)*sinf(phi) + sinf(psi)*sinf(theta)*cosf(phi);
    accelero_rotation[2][0] = -sinf(theta);
    accelero_rotation[2][1] = cosf(theta)*sinf(phi);
    accelero_rotation[2][2] = cosf(theta)*cosf(phi);
    
}



- (IBAction)starOff:(id)sender {
    
    [player stop];
    player.currentTime = 0;

    _timeLabel.text = @"00";
    _timeLabel_1.text = @"00:";
    _timeLabel_2.text = @"00:";
    timeValue = 0;
    timeValue_1 = 0;
    timeValue_2 = 0;
    _starOnBut.enabled = YES;
//    [_starOnBut setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _starOffBut.backgroundColor = [UIColor grayColor];
    _starOnBut.backgroundColor = [UIColor whiteColor];
    [_myTimer invalidate];
    
    kStarApp = NO;
    
}

- (IBAction)sliderAction:(UISlider *)sender {
    
    NSInteger sliderValum = sender.value * 100;
    _valumLabel.text = [NSString stringWithFormat:@"%ld",(long)sliderValum];
}

- (IBAction)feikongModelAction:(id)sender {
    kongzhiMode = NO;
    _feikongMode.backgroundColor = [UIColor grayColor];
    _kekongMode.backgroundColor = [UIColor whiteColor];
}

- (IBAction)kekongModeAction:(id)sender {
    kongzhiMode = YES;
    _kekongMode.backgroundColor = [UIColor grayColor];
    _feikongMode.backgroundColor = [UIColor whiteColor];
    
}
- (IBAction)ganyingText:(UITextField *)sender {
    minGanyingValue = -[sender.text floatValue];
    maxGanyingValue = [sender.text floatValue];
    _ganyingTextView.text = [NSString stringWithFormat:@"%.3f ~ %.3f",minGanyingValue,maxGanyingValue];
}
- (IBAction)denghouText:(UITextField *)sender {
    denghouTime = [sender.text integerValue];
    _denghouTextView.text = [NSString stringWithFormat:@"%ld",(long)denghouTime];
}

- (void)motionDataHandler
{
    
    static uint64_t previous_time = 0;
    if(previous_time == 0) previous_time = mach_absolute_time();
    
    uint64_t current_time = mach_absolute_time();
    static mach_timebase_info_data_t sTimebaseInfo;
    uint64_t elapsedNano;
    float dt = 0;
    
    static float highPassFilterX = 0.0, highPassFilterY = 0.0, highPassFilterZ = 0.0;
    
    CMAcceleration current_acceleration = { 0.0, 0.0, 0.0 };
    static CMAcceleration last_acceleration = { 0.0, 0.0, 0.0 };
    
    static bool first_time_accelero = TRUE;
    static bool first_time_gyro = TRUE;
    
    static float angle_gyro_x, angle_gyro_y, angle_gyro_z;
    float current_angular_rate_x, current_angular_rate_y, current_angular_rate_z;
    
    static float hpf_gyro_x, hpf_gyro_y, hpf_gyro_z;
    static float last_angle_gyro_x, last_angle_gyro_y, last_angle_gyro_z;
    
    float phi, theta;
    
    //dt calculus function of real elapsed time
    if(sTimebaseInfo.denom == 0) (void) mach_timebase_info(&sTimebaseInfo);
    elapsedNano = (current_time-previous_time)*(sTimebaseInfo.numer / sTimebaseInfo.denom);
    previous_time = current_time;
    dt = elapsedNano/1000000000.0;
    
    //Execute this part of code only on the joystick button pressed
    CMMotionManager *motionManager = [[AccManager shareManager] motionManager];
    
    //Get ACCELERO values
    if(motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1)
    {
        //Only accelerometer (iphone 3GS)
        current_acceleration.x = motionManager.accelerometerData.acceleration.x;
        current_acceleration.y = motionManager.accelerometerData.acceleration.y;
        current_acceleration.z = motionManager.accelerometerData.acceleration.z;
    }
    else if (motionManager.deviceMotionAvailable == 1)
    {
        //Accelerometer + gyro (iphone 4)
        current_acceleration.x = motionManager.deviceMotion.gravity.x + motionManager.deviceMotion.userAcceleration.x;
        current_acceleration.y = motionManager.deviceMotion.gravity.y + motionManager.deviceMotion.userAcceleration.y;
        current_acceleration.z = motionManager.deviceMotion.gravity.z + motionManager.deviceMotion.userAcceleration.z;
    }
    
    //NSLog(@"Before Shake %f %f %f",current_acceleration.x, current_acceleration.y, current_acceleration.z);
    
    if( isnan(current_acceleration.x) || isnan(current_acceleration.y) || isnan(current_acceleration.z)
       || fabs(current_acceleration.x) > 10 || fabs(current_acceleration.y) > 10 || fabs(current_acceleration.z)>10)
    {
        static uint32_t count = 0;
        //        static BOOL popUpWasDisplayed = NO;
        NSLog (@"Accelero errors : %f, %f, %f (count = %d)", current_acceleration.x, current_acceleration.y, current_acceleration.z, count);
        NSLog (@"Accelero raw : %f/%f, %f/%f, %f/%f", motionManager.deviceMotion.gravity.x, motionManager.deviceMotion.userAcceleration.x, motionManager.deviceMotion.gravity.y, motionManager.deviceMotion.userAcceleration.y, motionManager.deviceMotion.gravity.z, motionManager.deviceMotion.userAcceleration.z);
        NSLog (@"Attitude : %f / %f / %f", motionManager.deviceMotion.attitude.roll, motionManager.deviceMotion.attitude.pitch, motionManager.deviceMotion.attitude.yaw);
        return;
    }
    
    //INIT accelero variables
    if(first_time_accelero == TRUE)
    {
        first_time_accelero = FALSE;
        last_acceleration.x = current_acceleration.x;
        last_acceleration.y = current_acceleration.y;
        last_acceleration.z = current_acceleration.z;
    }
    
    float highPassFilterConstant = (1.0 / 5.0) / ((1.0 / 40) + (1.0 / 5.0)); // (1.0 / 5.0) / ((1.0 / kAPS) + (1.0 / 5.0));
    
    
    //HPF on the accelero
    highPassFilterX = highPassFilterConstant * (highPassFilterX + current_acceleration.x - last_acceleration.x);
    highPassFilterY = highPassFilterConstant * (highPassFilterY + current_acceleration.y - last_acceleration.y);
    highPassFilterZ = highPassFilterConstant * (highPassFilterZ + current_acceleration.z - last_acceleration.z);
    
    //Save the previous values
    last_acceleration.x = current_acceleration.x;
    last_acceleration.y = current_acceleration.y;
    last_acceleration.z = current_acceleration.z;
    
#define ACCELERO_THRESHOLD          0.2
#define ACCELERO_FASTMOVE_THRESHOLD	1.3
    
    if(fabs(highPassFilterX) > ACCELERO_FASTMOVE_THRESHOLD ||
       fabs(highPassFilterY) > ACCELERO_FASTMOVE_THRESHOLD ||
       fabs(highPassFilterZ) > ACCELERO_FASTMOVE_THRESHOLD){
        ;
    }
    else{
        if(accModeEnabled){
            if(accModeReady == NO){
                //                 NSLog(@"xxxxxxxxxx");
                //                [_aileronChannel setValue:0];//modify by dragon
               
            }
            else{
                
                
                CMAcceleration current_acceleration_rotate;
                float angle_acc_x;
                float angle_acc_y;
                
                //LPF on the accelero
                current_acceleration.x = 0.9 * last_acceleration.x + 0.1 * current_acceleration.x;
                current_acceleration.y = 0.9 * last_acceleration.y + 0.1 * current_acceleration.y;
                current_acceleration.z = 0.9 * last_acceleration.z + 0.1 * current_acceleration.z;
                
                //Save the previous values
                last_acceleration.x = current_acceleration.x;
                last_acceleration.y = current_acceleration.y;
                last_acceleration.z = current_acceleration.z;
                
                //Rotate the accelerations vectors
                current_acceleration_rotate.x =
                (accelero_rotation[0][0] * current_acceleration.x)
                + (accelero_rotation[0][1] * current_acceleration.y)
                + (accelero_rotation[0][2] * current_acceleration.z);
                current_acceleration_rotate.y =
                (accelero_rotation[1][0] * current_acceleration.x)
                + (accelero_rotation[1][1] * current_acceleration.y)
                + (accelero_rotation[1][2] * current_acceleration.z);
                current_acceleration_rotate.z =
                (accelero_rotation[2][0] * current_acceleration.x)
                + (accelero_rotation[2][1] * current_acceleration.y)
                + (accelero_rotation[2][2] * current_acceleration.z);
                
                //IF sequence to remove the angle jump problem when accelero mesure X angle AND Y angle AND Z change of sign
                if(current_acceleration_rotate.y > -ACCELERO_THRESHOLD && current_acceleration_rotate.y < ACCELERO_THRESHOLD)
                {
                    angle_acc_x = atan2f(current_acceleration_rotate.x,
                                         sign(-current_acceleration_rotate.z)*sqrtf(current_acceleration_rotate.y*current_acceleration_rotate.y+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                else
                {
                    angle_acc_x = atan2f(current_acceleration_rotate.x,
                                         sqrtf(current_acceleration_rotate.y*current_acceleration_rotate.y+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                
                //IF sequence to remove the angle jump problem when accelero mesure X angle AND Y angle AND Z change of sign
                if(current_acceleration_rotate.x > -ACCELERO_THRESHOLD && current_acceleration_rotate.x < ACCELERO_THRESHOLD)
                {
                    angle_acc_y = atan2f(current_acceleration_rotate.y,
                                         sign(-current_acceleration_rotate.z)*sqrtf(current_acceleration_rotate.x*current_acceleration_rotate.x+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                else
                {
                    angle_acc_y = atan2f(current_acceleration_rotate.y,
                                         sqrtf(current_acceleration_rotate.x*current_acceleration_rotate.x+current_acceleration_rotate.z*current_acceleration_rotate.z));
                }
                
                //NSLog(@"AccX %2.2f   AccY %2.2f   AccZ %2.2f",current_acceleration.x,current_acceleration.y,current_acceleration.z);
                
                /***************************************************************************************************************
                 GYRO HANDLE IF AVAILABLE
                 **************************************************************************************************************/
                if (motionManager.deviceMotionAvailable == 1)
                {
                    current_angular_rate_x = motionManager.deviceMotion.rotationRate.x;
                    current_angular_rate_y = motionManager.deviceMotion.rotationRate.y;
                    current_angular_rate_z = motionManager.deviceMotion.rotationRate.z;
                    
                    angle_gyro_x += -current_angular_rate_x * dt;
                    angle_gyro_y += current_angular_rate_y * dt;
                    angle_gyro_z += current_angular_rate_z * dt;
                    
                    if(first_time_gyro == TRUE)
                    {
                        first_time_gyro = FALSE;
                        
                        //Init for the integration samples
                        angle_gyro_x = 0;
                        angle_gyro_y = 0;
                        angle_gyro_z = 0;
                        
                        //Init for the HPF calculus
                        hpf_gyro_x = angle_gyro_x;
                        hpf_gyro_y = angle_gyro_y;
                        hpf_gyro_z = angle_gyro_z;
                        
                        last_angle_gyro_x = 0;
                        last_angle_gyro_y = 0;
                        last_angle_gyro_z = 0;
                    }
                    
                    //HPF on the gyro to keep the hight frequency of the sensor
                    hpf_gyro_x = 0.9 * hpf_gyro_x + 0.9 * (angle_gyro_x - last_angle_gyro_x);
                    hpf_gyro_y = 0.9 * hpf_gyro_y + 0.9 * (angle_gyro_y - last_angle_gyro_y);
                    hpf_gyro_z = 0.9 * hpf_gyro_z + 0.9 * (angle_gyro_z - last_angle_gyro_z);
                    
                    last_angle_gyro_x = angle_gyro_x;
                    last_angle_gyro_y = angle_gyro_y;
                    last_angle_gyro_z = angle_gyro_z;
                }
                
                /******************************************************************************RESULTS AND COMMANDS COMPUTATION
                 *****************************************************************************/
                //Sum of hight gyro frequencies and low accelero frequencies
                float fusion_x = hpf_gyro_y + angle_acc_x;
                float fusion_y = hpf_gyro_x + angle_acc_y;
                
                //NSLog(@"%*.2f  %*.2f  %*.2f  %*.2f  %*.2f",2,-angle_acc_x*180/PI,2,-angle_acc_y*180/PI,2,current_acceleration_rotate.x,2,current_acceleration_rotate.y,2,current_acceleration_rotate.z);
                //Adapt the command values Normalize between -1 = 1.57rad and 1 = 1.57 rad
                //and reverse the values in regards of the screen orientation
                if(motionManager.gyroAvailable == 0 && motionManager.accelerometerAvailable == 1)
                {
                    //Only accelerometer (iphone 3GS)
                    if(1)//screenOrientationRight
                    {
                        theta = -angle_acc_x;
                        phi = -angle_acc_y;
                    }
                    //                    else
                    //                    {
                    //                        theta = angle_acc_x;
                    //                        phi = angle_acc_y;
                    //                    }
                }
                if (motionManager.deviceMotionAvailable == 1)
                {
                    theta = -fusion_x;
                    phi = fusion_y;
                }
                
                //Clamp the command sent
                //                theta = theta / M_PI_2;
                //                phi   = phi / M_PI_2;
                theta = theta / M_1_PI;
                phi = phi / M_1_PI;
                if(theta > 1)
                    theta = 1;
                if(theta < -1)
                    theta = -1;
                if(phi > 1)
                    phi = 1;
                if(phi < -1)
                    phi = -1;
                
    
            }
        }
        else{
            if (accModeReady) {
            }
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
