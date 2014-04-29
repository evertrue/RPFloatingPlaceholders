//
//  ViewController.m
//  FloatLabeledTextViewExample
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//

#import "ViewController.h"
#import "RPFloatingPlaceholderTextField.h"
#import "RPFloatingPlaceholderTextView.h"

@interface ViewController () {
    
}

@property (nonatomic, strong) IBOutlet RPFloatingPlaceholderTextField *textFieldOne;
@property (nonatomic, strong) IBOutlet RPFloatingPlaceholderTextField *textFieldTwo;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textFieldOne.regexpPattern = @".{8,}"; /// e.g. %MQ24=6A
    self.textFieldOne.regexpValidColor = [UIColor greenColor];
    self.textFieldOne.regexpInvalidColor = [UIColor redColor];
    
    self.textFieldTwo.regexpPattern = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*"; /// e.g. example@gmail.com
    self.textFieldTwo.regexpValidColor = [UIColor greenColor];
    self.textFieldTwo.regexpInvalidColor = [UIColor redColor];
}

- (IBAction)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

@end
