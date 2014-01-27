//
//  RPFloatingPlaceholderTextField.h
//  RPFloatingPlaceholders
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//
//  See LICENSE for full license agreement.
//

#import <UIKit/UIKit.h>
#import "RPFloatingPlaceholderConstants.h"

typedef enum {
    ValidationPassed = 0,
    ValidationFailed,
    ValueTooShortToValidate
} ValidationResult;

typedef void (^ValidationBlock)(ValidationResult result, BOOL isEditing);

#pragma mark - RPFloatingPlaceholderTextField
@interface RPFloatingPlaceholderTextField : UITextField

/**
 Enum to switch between upward and downward animation of the floating label.
 */
@property (nonatomic) RPFloatingPlaceholderAnimationOptions animationDirection;

/**
 The floating label that is displayed above the text field when there is other
 text in the text field.
 */
@property (nonatomic, strong, readonly) UILabel *floatingLabel;

/**
 The color of the floating label displayed above the text field when it is in
 an active state (i.e. the associated text view is first responder).
 
 @discussion Note: Tint color is used by default if this is nil.
 */
@property (nonatomic, strong) UIColor *floatingLabelActiveTextColor;

/**
 The color of the floating label displayed above the text field when it is in
 an inactive state (i.e. the associated text view is not first responder).
 
 @discussion Note: 70% gray is used by default if this is nil.
 */
@property (nonatomic, strong) UIColor *floatingLabelInactiveTextColor;


#pragma mark - TSValidatedTextField

#pragma mark - Basics
/** If defined field will be checked.
 Remember to define images for both valid and invalid states.
 Default set to nil. */
@property (nonatomic, strong) NSString *regexpPattern;

/** You can set your own regexp object.
 Default regexp is initialized with pattern:@"" and options:0.
 */
@property (nonatomic, strong) NSRegularExpression *regexp;

#pragma mark - Accessors
/** Return YES if value is valid. Otherwise NO. (read-only)*/
@property (nonatomic, readonly) BOOL isValid;


#pragma mark - Visualization
/** Text color for valid value in the field.
 If set to nil self.textColor will be used.
 Default set to nil. */
@property (nonatomic, strong) UIColor *regexpValidColor;

/** Text color for valid value in the field.
 If set to nil self.textColor will be used.
 Default set to nil. */
@property (nonatomic, strong) UIColor *regexpInvalidColor;


#pragma mark - Blocks
/** When block is defined it is called each time when value in the field has been validated.
 Default set to nil. (read-write)*/
@property (readwrite, copy) ValidationBlock validatedFieldBlock;


#pragma mark - Settings
/** If set to NO text will be validated when editing is done.
 Default set to YES. */
@property (nonatomic, getter = isValidWhenType) BOOL validWhenType;

/** If set to YES and user change value all occurences of the pattern will be checked.
 Field will be valid if all of the text will be valid. Otherwise invalid.
 Default set to NO. */
@property (nonatomic, getter = isLooksForManyOccurences) BOOL looksForManyOccurences;

/** This value should be set when looksForManyOccurences = YES.
 When the field is validating and looks for many occurences validator can separate occurences by values in this array.
 If looksForManyOccurences is set to YES and occurencesSeparators is set to e.g @[",", ", "] the many occurences will be validated.
 E.g. number validating "5, 10, -10, 20". Result of validation will be ValidationPassed.
 If this value isn't set it didn't match above example.
 Default set to nil. */
@property (nonatomic, strong) NSArray *occurencesSeparators;

/** Field is validate when its value will be equal or longer than set number.
 If text is shorter than this value the field looks normal (both colors valid and invalid aren't apply
 but block has been called with ValueTooShortToValidate parameter).
 Default set to 1 (minimum value). */
@property (nonatomic) NSUInteger minimalNumberOfCharactersToStartValidation;

@end
