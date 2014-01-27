//
//  RPFloatingPlaceholderTextField.m
//  RPFloatingPlaceholders
//
//  Created by Rob Phillips on 10/19/13.
//  Copyright (c) 2013 Rob Phillips. All rights reserved.
//
//  See LICENSE for full license agreement.
//

#import "RPFloatingPlaceholderTextField.h"

@interface RPFloatingPlaceholderTextField () {
    ValidationResult _validationResult;
    NSString *_previousText;
}

#pragma mark - RPFloatingPlaceholderTextField
/**
 Used to cache the placeholder string.
 */
@property (nonatomic, strong) NSString *cachedPlaceholder;

/**
 Used to draw the placeholder string if necessary.
 */
@property (nonatomic, assign) BOOL shouldDrawPlaceholder;

/**
 Frames used to animate the floating label and text field into place.
 */
@property (nonatomic, assign) CGRect originalTextFieldFrame;
@property (nonatomic, assign) CGRect offsetTextFieldFrame;
@property (nonatomic, assign) CGRect originalFloatingLabelFrame;
@property (nonatomic, assign) CGRect offsetFloatingLabelFrame;

#pragma mark - TSValidatedTextField
@property (nonatomic, readonly) BOOL canValid;
@property (nonatomic, strong) UIColor *baseColor;
@property (nonatomic) BOOL fieldHasBeenEdited;

@end

@implementation RPFloatingPlaceholderTextField

@synthesize regexpInvalidColor = _regexpInvalidColor;
@synthesize regexpValidColor = _regexpValidColor;
@synthesize regexpPattern = _regexpPattern;
@synthesize validWhenType = _validWhenType;
@synthesize minimalNumberOfCharactersToStartValidation = _minimalNumberOfCharactersToStartValidation;
@synthesize looksForManyOccurences = _looksForManyOccurences;

#pragma mark - Programmatic Initializer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Setup the view defaults
        [self setupViewDefaults];
        [self configureForValidation];
    }
    return self;
}

#pragma mark - Nib/Storyboard Initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Setup the view defaults
        [self setupViewDefaults];
        [self configureForValidation];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Ensures that the placeholder & text are set through our custom setters
    // when loaded from a nib/storyboard.
    self.placeholder = self.placeholder;
    self.text = self.text;
}

- (void)configureForValidation
{
    _minimalNumberOfCharactersToStartValidation = 1;
    _validWhenType = YES;
    _fieldHasBeenEdited = NO;
    _validationResult = ValidationFailed;
    _occurencesSeparators = nil;
    [self setRegexpPattern:@""];
}

#pragma mark - Unsupported Initializers

- (instancetype)init {
    [NSException raise:NSInvalidArgumentException format:@"%s Using the %@ initializer directly is not supported. Use %@ instead.", __PRETTY_FUNCTION__, NSStringFromSelector(@selector(init)), NSStringFromSelector(@selector(initWithFrame:))];
    return nil;
}

#pragma mark - Dealloc

- (void)dealloc
{
    // Remove the text view observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setters & Getters

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self textFieldTextDidChange:nil];
    [self validateFieldWithIsEditing:self.isEnabled];
}

- (void)setPlaceholder:(NSString *)aPlaceholder
{
    if ([_cachedPlaceholder isEqualToString:aPlaceholder]) return;
    
    // We draw the placeholder ourselves so we can control when it is shown
    // during the animations
    [super setPlaceholder:nil];
    
    _cachedPlaceholder = aPlaceholder;
    
    _floatingLabel.text = _cachedPlaceholder;
    [self adjustFramesForNewPlaceholder];
    
    // Flags the view to redraw
    [self setNeedsDisplay];
}

- (BOOL)hasText
{
    return self.text.length != 0;
}

#pragma mark - View Defaults

- (void)setupViewDefaults
{
    // Add observers for the text field state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditing:)
                                                 name:UITextFieldTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidEndEditing:)
                                                 name:UITextFieldTextDidEndEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification object:self];
    
    // Set the default animation direction
    self.animationDirection = RPFloatingPlaceholderAnimateUpward;
    
    // Setup default colors for the floating label states
    UIColor *defaultActiveColor = [self respondsToSelector:@selector(tintColor)] ? self.tintColor : [UIColor blueColor]; // iOS 6
    self.floatingLabelActiveTextColor = defaultActiveColor;
    self.floatingLabelInactiveTextColor = [UIColor colorWithWhite:0.7f alpha:1.f];
    
    // Create the floating label instance and add it to the view
    _floatingLabel = [[UILabel alloc] init];
    _floatingLabel.font = [UIFont boldSystemFontOfSize:11.f];
    _floatingLabel.textColor = self.floatingLabelActiveTextColor;
    _floatingLabel.backgroundColor = [UIColor clearColor];
    _floatingLabel.alpha = 1.f;
    
    // Adjust the top margin of the text field and then cache the original
    // view frame
    _originalTextFieldFrame = UIEdgeInsetsInsetRect(self.frame, UIEdgeInsetsMake(5.f, 0.f, 2.f, 0.f));
    self.frame = _originalTextFieldFrame;
    
    // Set the background to a clear color
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Drawing & Animations

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Check if we need to redraw for pre-existing text
    if (![self isFirstResponder]) {
        [self checkForExistingText];
    }
}

- (void)drawRect:(CGRect)aRect
{
    [super drawRect:aRect];
    
    // Check if we should draw the placeholder string.
    // Use RGB values found via Photoshop for placeholder color #c7c7cd.
    if (_shouldDrawPlaceholder) {
        UIColor *placeholderGray = [UIColor colorWithRed:199/255.f green:199/255.f blue:205/255.f alpha:1.f];
        CGRect placeholderFrame = CGRectMake(5.f, floorf((self.frame.size.height - self.font.lineHeight) / 2.f), self.frame.size.width, self.frame.size.height);
        NSDictionary *placeholderAttributes = @{NSFontAttributeName : self.font,
                                                NSForegroundColorAttributeName : placeholderGray};
        
        if ([self respondsToSelector:@selector(tintColor)]) {
            [_cachedPlaceholder drawInRect:placeholderFrame
                            withAttributes:placeholderAttributes];
            
        } else {
            NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] initWithString:_cachedPlaceholder
                                                                                        attributes:placeholderAttributes];
            [attributedPlaceholder drawInRect:placeholderFrame];
        } // iOS 6
        
    }
}

- (void)showFloatingLabelWithAnimation:(BOOL)isAnimated
{
    // Add it to the superview
    if (!_floatingLabel.superview) {
        [self.superview addSubview:_floatingLabel];
    }
    
    // Flags the view to redraw
    [self setNeedsDisplay];
    
    if (isAnimated) {
        __weak typeof(self) weakSelf = self;
        UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut;
        [UIView animateWithDuration:0.2f delay:0.f options:options animations:^{
            _floatingLabel.alpha = 1.f;
            if (weakSelf.animationDirection == RPFloatingPlaceholderAnimateDownward) {
                weakSelf.frame = _offsetTextFieldFrame;
            } else {
                _floatingLabel.frame = _offsetFloatingLabelFrame;
            }
        } completion:nil];
    } else {
        _floatingLabel.alpha = 1.f;
        if (self.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            self.frame = _offsetTextFieldFrame;
        } else {
            _floatingLabel.frame = _offsetFloatingLabelFrame;
        }
    }
}

- (void)hideFloatingLabel
{
    __weak typeof(self) weakSelf = self;
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn;
    [UIView animateWithDuration:0.2f delay:0.f options:options animations:^{
        _floatingLabel.alpha = 0.f;
        if (weakSelf.animationDirection == RPFloatingPlaceholderAnimateDownward) {
            weakSelf.frame = _originalTextFieldFrame;
        } else {
            _floatingLabel.frame = _originalFloatingLabelFrame;
        }
    } completion:^(BOOL finished) {
        // Flags the view to redraw
        [weakSelf setNeedsDisplay];
    }];
}

- (void)checkForExistingText
{
    // Check if we need to redraw for pre-existing text
    _shouldDrawPlaceholder = !self.hasText;
    if (self.hasText) {
        _floatingLabel.textColor = self.floatingLabelInactiveTextColor;
        [self showFloatingLabelWithAnimation:NO];
    }
}

- (void)adjustFramesForNewPlaceholder
{
    [_floatingLabel sizeToFit];
    
    CGFloat offset = _floatingLabel.font.lineHeight;
    
    _originalFloatingLabelFrame = CGRectMake(_originalTextFieldFrame.origin.x + 5.f, _originalTextFieldFrame.origin.y,
                                             _originalTextFieldFrame.size.width - 10.f, _floatingLabel.frame.size.height);
    _floatingLabel.frame = _originalFloatingLabelFrame;
    
    _offsetFloatingLabelFrame = CGRectMake(_originalFloatingLabelFrame.origin.x, _originalFloatingLabelFrame.origin.y - offset,
                                           _originalFloatingLabelFrame.size.width, _originalFloatingLabelFrame.size.height);
    
    _offsetTextFieldFrame = CGRectMake(_originalTextFieldFrame.origin.x, _originalTextFieldFrame.origin.y + offset,
                                       _originalTextFieldFrame.size.width, _originalTextFieldFrame.size.height);
}

// Adds padding so these text fields align with RPFloatingPlaceholderTextView's
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0.f, 5.f, 0.f, 5.f))];
}

// Adds padding so these text fields align with RPFloatingPlaceholderTextView's
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [super editingRectForBounds:UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0.f, 5.f, 0.f, 5.f))];
}

- (void)animateFloatingLabelColorChangeWithAnimationBlock:(void (^)(void))animationBlock
{
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionTransitionCrossDissolve;
    [UIView transitionWithView:_floatingLabel duration:0.25 options:options animations:^{
        animationBlock();
    } completion:nil];
}

#pragma mark - Text Field Observers

- (void)textFieldDidBeginEditing:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        _floatingLabel.textColor = weakSelf.floatingLabelActiveTextColor;
    }];
}

- (void)textFieldDidEndEditing:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self animateFloatingLabelColorChangeWithAnimationBlock:^{
        _floatingLabel.textColor = weakSelf.floatingLabelInactiveTextColor;
    }];
}

- (void)textFieldTextDidChange:(NSNotification *)notification
{
    BOOL _previousShouldDrawPlaceholderValue = _shouldDrawPlaceholder;
    _shouldDrawPlaceholder = !self.hasText;
    
    // Only redraw if _shouldDrawPlaceholder value was changed
    if (_previousShouldDrawPlaceholderValue != _shouldDrawPlaceholder) {
        if (_shouldDrawPlaceholder) {
            [self hideFloatingLabel];
        } else {
            [self showFloatingLabelWithAnimation:YES];
        }
    }
}

#pragma mark - TSValidatedTextField

#pragma mark - Lifecycle of validation
- (void)validateFieldWithIsEditing:(BOOL)isEditing {
    if (!_previousText || ![_previousText isEqualToString:self.text])
    {
        _previousText = self.text;
        if (self.text.length > 0 && !_fieldHasBeenEdited)
            _fieldHasBeenEdited = YES;
        
        if (_fieldHasBeenEdited)
        {
            [self willChangeValueForKey:@"isValid"];
            _validationResult = [self validRegexp];
            [self didChangeValueForKey:@"isValid"];
            
            if (self.text.length >= _minimalNumberOfCharactersToStartValidation)
            {
                [self updateViewForState:_validationResult];
                
                if (_validatedFieldBlock)
                    _validatedFieldBlock(_validationResult, isEditing);
            }
            else if (self.text.length == 0 ||
                     self.text.length < _minimalNumberOfCharactersToStartValidation)
            {
                if (_baseColor)
                    self.textColor = _baseColor;
                
                if (_validatedFieldBlock)
                    _validatedFieldBlock(ValueTooShortToValidate, isEditing);
            }
        }
    }
    
}


- (BOOL)isEditing
{
    BOOL isEditing = [super isEditing];
    if ((isEditing && _validWhenType) ||
        (!isEditing && !_validWhenType)) {
        [self validateFieldWithIsEditing:isEditing];
    }
    
    return isEditing;
}


#pragma mark - Accessors
- (BOOL)isValid
{
    if (_validationResult == ValidationPassed)
        return YES;
    else
        return NO;
}

- (BOOL)isLooksForManyOccurences
{
    return _looksForManyOccurences;
}

- (void)setLooksForManyOccurences:(BOOL)looksForManyOccurences
{
    _looksForManyOccurences = looksForManyOccurences;
}

- (BOOL)isValidWhenType
{
    return _validWhenType;
}

- (void)setValidWhenType:(BOOL)validWhenType
{
    _validWhenType = validWhenType;
}

- (void)setMinimalNumberOfCharactersToStartValidation:(NSUInteger)minimalNumberOfCharacterToStartValidation
{
    if (minimalNumberOfCharacterToStartValidation  < 1)
        minimalNumberOfCharacterToStartValidation = 1;
    _minimalNumberOfCharactersToStartValidation = minimalNumberOfCharacterToStartValidation;
}

- (NSUInteger)minimalNumberOfCharactersToStartValidation
{
    return _minimalNumberOfCharactersToStartValidation;
}


#pragma mark - Regexp Pattern accessors
- (void)setRegexpPattern:(NSString *)regexpPattern
{
    if (!regexpPattern)
        regexpPattern = @"";
    
    [self configureRegexpWithPattern:regexpPattern];
}

- (NSString *)regexpPattern
{
    return _regexp.pattern;
}

- (void)configureRegexpWithPattern:(NSString *)pattern
{
    _regexp = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
}


#pragma mark - Regexp Colors accessors
- (void)setRegexpInvalidColor:(UIColor *)regexpInvalidColor
{
    if (!_baseColor)
        _baseColor = self.textColor;
    _regexpInvalidColor = regexpInvalidColor;
}

- (UIColor *)regexpInvalidColor
{
    return _regexpInvalidColor;
}

- (void)setRegexpValidColor:(UIColor *)regexpValidColor
{
    if (!_baseColor)
        _baseColor = self.textColor;
    _regexpValidColor = regexpValidColor;
}

- (UIColor *)regexpValidColor
{
    return _regexpValidColor;
}


#pragma mark - Validation View Management
- (void)updateViewForState:(ValidationResult)result
{
    UIImageView *imageView = (UIImageView *)self.rightView;
    
    BOOL canShow = self.canValid;
    imageView.hidden = !canShow;
    
    if (canShow)
    {
        UIColor *color = self.textColor;
        if (result == ValidationPassed && _regexpValidColor) {
            color = _regexpValidColor;
        } else if (result == ValidationFailed && _regexpInvalidColor) {
            color = _regexpInvalidColor;
        }
        self.floatingLabel.textColor = color;
    }
}

- (BOOL)canValid
{
    return _regexp.pattern != nil;
}


#pragma mark - Validation
- (ValidationResult)validRegexp
{
    NSString *text = self.text;
    ValidationResult valid = ValidationPassed;
    if (self.canValid)
    {
        NSRange textRange = NSMakeRange(0, text.length);
        NSArray *matches = [_regexp matchesInString:text options:0 range:textRange];
        
        NSRange resultRange = NSMakeRange(NSNotFound, 0);
        if (matches.count == 1 && !_looksForManyOccurences)
        {
            NSTextCheckingResult *result = (NSTextCheckingResult *)matches[0];
            resultRange = result.range;
        }
        else if (matches.count != 0 && self.isLooksForManyOccurences)
        {
            resultRange = [self rangeFromTextCheckingResults:matches];
        }
        
        if (NSEqualRanges(textRange, resultRange))
            valid = ValidationPassed;
        else
            valid = ValidationFailed;
    }
    
    return valid;
}

- (NSRange)rangeFromTextCheckingResults:(NSArray *)array
{
    /// Valid first match
    NSTextCheckingResult *firstResult = (NSTextCheckingResult *)array[0];
    if (!(firstResult.range.location == 0 && firstResult.range.length > 0))
        return NSMakeRange(NSNotFound, 0);
    
    
    /// Valid all matches
    NSInteger lastLocation = 0;
    
    if (array.count > 0)
    {
        for (NSTextCheckingResult *result in array)
        {
            if (lastLocation == result.range.location)
                lastLocation = result.range.location + result.range.length;
            else if (lastLocation < result.range.location)
            {
                NSString *stringInRange = [self.text substringWithRange:NSMakeRange(lastLocation, result.range.location - lastLocation)];
                
                BOOL separatorValid = NO;
                if (_occurencesSeparators)
                {
                    for (NSString *separator in _occurencesSeparators)
                    {
                        if ([stringInRange isEqualToString:separator])
                        {
                            lastLocation = result.range.location + result.range.length;
                            separatorValid = YES;
                            break;
                        }
                    }
                }
                
                if (separatorValid)
                    lastLocation = result.range.location + result.range.length;
                else
                    break;
            }
            else
                break;
        }
    }
    
    return NSMakeRange(0, lastLocation);
}


@end
