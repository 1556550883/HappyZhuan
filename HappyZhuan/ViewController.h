//
//  ViewController.h
//  HappyZhuan
//
//  Created by 文高坡 on 2019/2/12.
//  Copyright © 2019年 文高坡. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ViewController : UIViewController
@property (nonatomic, retain) IBOutlet UIView *tfbgview;

@property (nonatomic, retain) IBOutlet UIImageView *bgimage;
@property (nonatomic, retain) IBOutlet UIButton *registerudid;
@property (nonatomic, retain) IBOutlet UIButton *start_btn;
@property (nonatomic, retain) IBOutlet UIButton *openinstall_btn;
@property (nonatomic, retain) IBOutlet UILabel *tip_label;
@property (nonatomic, retain) IBOutlet UILabel *appid_label;


- (IBAction) registerUser:(id)obj;
- (IBAction) startTask:(id)obj;
- (IBAction) installOpen:(id)obj;
@end

