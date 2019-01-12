//
//  ViewController.m
//  OpenCVLearn
//
//  Created by 曾坚 on 2019/1/9.
//  Copyright © 2019年 JK. All rights reserved.
//

#include "opencv2.framework/Headers/stitching/detail/blenders.hpp"
#include "opencv2.framework/Headers/stitching/detail/exposure_compensate.hpp"
#include "opencv2.framework/Headers/stitching/detail/seam_finders.hpp"
#import "ViewController.h"
#include "opencv2.framework/Headers/opencv.hpp"
#import "opencv2.framework/Headers/videoio/cap_ios.h"

@interface ViewController ()<CvVideoCameraDelegate>

@property (nonatomic, strong) UIView *backView;

@property (nonatomic, strong) CvVideoCamera *camera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.backView = [[UIView alloc] init];
    self.backView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 50);
    [self.view addSubview:self.backView];
    
    self.camera = [[CvVideoCamera alloc] initWithParentView:self.backView];
    self.camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.camera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
    self.camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.camera.defaultFPS = 30;
    self.camera.grayscaleMode = NO;
    self.camera.delegate = self;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.camera start];
}

#pragma mark - opencv delegate

- (void)processImage:(cv::Mat &)image
{
    if (image.empty()) {
        return;
    }
    [self faceDetector:image];
}

#pragma mark - actions

- (void)revertColor:(cv::Mat &)image
{
    // Do some OpenCV stuff with the image
    cv::Mat image_copy;
    cv::cvtColor(image, image_copy, cv::COLOR_BGRA2BGR);
    // invert image
    cv::bitwise_not(cv::_InputArray((cv::Mat &)image_copy), cv::_OutputArray((cv::Mat &)image_copy));
    cv::cvtColor(image_copy, image, cv::COLOR_BGR2BGRA);
    
//    gray
//    // Do some OpenCV stuff with the image
//    cv::Mat image_copy;
//    cv::cvtColor(image, image, cv::COLOR_RGB2GRAY);
    
}

- (void)lsdDetetor:(cv::Mat &)image
{
    /*https://docs.opencv.org/4.0.1/d1/d9e/fld_lines_8cpp-example.html*/
    
    cv::Ptr<cv::LineSegmentDetector> lsd = cv::createLineSegmentDetector(cv::LSD_REFINE_ADV);
    std::vector<cv::Vec4f> lines_lsd;
    cv::Mat image_copy;
    cv::cvtColor(image,image_copy, cv::COLOR_BGR2GRAY);
    
    //fld not found in framework ??
//    int length_threshold = 10;
//    float distance_threshold = 1.41421356f;
//    double canny_th1 = 50.0;
//    double canny_th2 = 50.0;
//    int canny_aperture_size = 3;
//    bool do_merge = false;
    
//    for(int run_count = 0; run_count < 10; run_count++) {
        lines_lsd.clear();
//        int64 start_lsd = cv::getTickCount();
        lsd->detect(image_copy, lines_lsd);
        // Detect the lines with LSD
//        double freq = cv::getTickFrequency();
//        double duration_ms_lsd = double(cv::getTickCount() - start_lsd) * 1000 / freq;
//        std::cout << "Elapsed time for LSD: "
//        << std::setw(10) << std::setiosflags(std::ios::right) << std::setiosflags(std::ios::fixed) << std::setprecision(2)
//        << duration_ms_lsd << " ms." << std::endl;
//    }
    
    cv::Mat _lines = cv::InputArray(lines_lsd).getMat();
//#define CV_32S  4
//#define CV_32F  5
    const int depth = _lines.depth();
    
    if (depth == 0) {
        return;
    }

    cv::Mat blank_img(image_copy.size(),CV_8U,cv::Scalar(255,255,255));
    // Show found lines with LSD
    lsd->drawSegments(blank_img, lines_lsd);
    
//    cv::cvtColor(image_copy, image, cv::COLOR_GRAY2BGR);
    image = blank_img;

    
}

- (void)shape_example
{
    
}

static int thresh = 100;

- (void)contours:(cv::Mat &)image
{
    /*https://docs.opencv.org/4.0.1/da/d32/samples_2cpp_2contours2_8cpp-example.html*/
    
    
    cv::Mat image_copy;
    cv::cvtColor(image,image_copy, cv::COLOR_BGR2GRAY);
//    image.convertTo(image_copy, CV_8UC1);
    
//    cv::Mat dst = cv::Mat(image_copy.size(), CV_8UC3,cv::Scalar(0,0,0));
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    
    cv::Mat output;
    
    //compare
//    cv::compare(image_copy, image_copy, output, cv::CMP_EQ);
    //threshold
//    double tt = cv::threshold(image_copy, output, thresh, thresh * 2, cv::THRESH_BINARY_INV);
    //inRange
//    cv::inRange(image_copy, cv::Scalar(0,10,0), cv::Scalar(255,100,255), output);
    //adaptiveTreshold
//    cv::adaptiveThreshold(image_copy, output, 1, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 3, -1);
    //canny
    cv::Canny(image_copy, output, thresh, thresh*2, 3);
    
    
    cv::findContours(output, contours, hierarchy,
                 cv::RETR_CCOMP, cv::CHAIN_APPROX_SIMPLE);
    // iterate through all the top-level contours,
    // draw each connected component with its own random color
//    int idx = 0;
//    for( ; idx >= 0; idx = hierarchy[idx][0] )
//    {
    
    cv::Mat blank_img(image_copy.size(),CV_8U,cv::Scalar(0,0,0));
//    for( int i = 0; i< contours.size(); i++ ){
        cv::Scalar color(255, 255, 255);
    /// -1 means draw all point
        cv::drawContours(blank_img, contours, -1, color, 2, cv::LINE_8, hierarchy);
//    }
    image = blank_img;
}


static cv::CascadeClassifier cascade , nestedCascade;
static bool tryflip = false;
static double scale = 1.3;
const static cv::Scalar colors[] =
{
    cv::Scalar(255,0,0),
    cv::Scalar(255,128,0),
    cv::Scalar(255,255,0),
    cv::Scalar(0,255,0),
    cv::Scalar(0,128,255),
    cv::Scalar(0,255,255),
    cv::Scalar(0,0,255),
    cv::Scalar(255,0,255)
};

- (void)faceDetector:(cv::Mat &)image
{
    /*https://docs.opencv.org/4.0.1/d4/d26/samples_2cpp_2facedetect_8cpp-example.html*/
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *fontface = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
        NSString *eyes = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye_tree_eyeglasses" ofType:@"xml"];
        cascade.load(cv::samples::findFile([fontface cStringUsingEncoding:NSUTF8StringEncoding]));
        nestedCascade.load(cv::samples::findFile([eyes cStringUsingEncoding:NSUTF8StringEncoding]));
    });
    
//    double t = 0;
    std::vector<cv::Rect> faces, faces2;
    cv::Mat gray, smallImg;
    cvtColor(image, gray, cv::COLOR_BGR2GRAY );
    double fx = 1 / scale;
    cv::resize( gray, smallImg, cv::Size(), fx, fx, cv::INTER_LINEAR_EXACT );
    equalizeHist( smallImg, smallImg );
//    t = (double)cv::getTickCount();
    cascade.detectMultiScale( smallImg, faces,
                             1.1, 2, 0
                             //|CASCADE_FIND_BIGGEST_OBJECT
                             //|CASCADE_DO_ROUGH_SEARCH
                             |cv::CASCADE_SCALE_IMAGE,
                             cv::Size(50, 50) );
    if( tryflip )
    {
        flip(smallImg, smallImg, 1);
        cascade.detectMultiScale( smallImg, faces2,
                                 1.1, 2, 0
                                 //|CASCADE_FIND_BIGGEST_OBJECT
                                 //|CASCADE_DO_ROUGH_SEARCH
                                 |cv::CASCADE_SCALE_IMAGE,
                                 cv::Size(50, 50) );
        for( std::vector<cv::Rect>::const_iterator r = faces2.begin(); r != faces2.end(); ++r )
        {
            faces.push_back(cv::Rect(smallImg.cols - r->x - r->width, r->y, r->width, r->height));
        }
    }
//    t = (double)cv::getTickCount() - t;
//    printf( "detection time = %g ms\n", t*1000/cv::getTickFrequency());
    for ( size_t i = 0; i < faces.size(); i++ )
    {
        cv::Rect r = faces[i];
        cv::Mat smallImgROI;
        std::vector<cv::Rect> nestedObjects;
        cv::Point center;
        int radius;
        double aspect_ratio = (double)r.width/r.height;
        if( 0.75 < aspect_ratio && aspect_ratio < 1.3 )
        {
            center.x = cvRound((r.x + r.width*0.5)*scale);
            center.y = cvRound((r.y + r.height*0.5)*scale);
            radius = cvRound((r.width + r.height)*0.25*scale);
            circle( image, center, radius, colors[3], 3, 8, 0 );
        }
        else
            rectangle( image, cv::Point(cvRound(r.x*scale), cvRound(r.y*scale)),
                      cv::Point(cvRound((r.x + r.width-1)*scale), cvRound((r.y + r.height-1)*scale)),
                      colors[0], 3, 8, 0);
        if( nestedCascade.empty() )
            continue;
        smallImgROI = smallImg( r );
        
        nestedCascade.detectMultiScale( smallImgROI, nestedObjects,
                                       1.1, 2, 0
                                       //|CASCADE_FIND_BIGGEST_OBJECT
                                       //|CASCADE_DO_ROUGH_SEARCH
                                       //|CASCADE_DO_CANNY_PRUNING
                                       |cv::CASCADE_SCALE_IMAGE,
                                       cv::Size(30, 30) );
        for ( size_t j = 0; j < nestedObjects.size(); j++ )
        {
            cv::Rect nr = nestedObjects[j];
            center.x = cvRound((r.x + nr.x + nr.width*0.5)*scale);
            center.y = cvRound((r.y + nr.y + nr.height*0.5)*scale);
            radius = cvRound((nr.width + nr.height)*0.25*scale);
            circle( image, center, radius, colors[6], 3, 8, 0 );
        }
    }
}

- (void)filter:(cv::Mat &)image
{
    
}


@end
