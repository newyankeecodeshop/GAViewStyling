/*
 Copyright (c) 2011 Andrew Goodale. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this list of
 conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this list
 of conditions and the following disclaimer in the documentation and/or other materials
 provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY ANDREW GOODALE "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those of the
 authors and should not be interpreted as representing official policies, either expressed
 or implied, of Andrew Goodale.
 */

#import "UIView+GAViewStyling.h"
#import "GAViewStyling.h"
#import "GAScriptEngine.h"
#import "NSObject+GAJavaScript.h"
#import "GAScriptMethodSignatures.h"

CAGradientLayer* GAGradientSubLayerForLayer (CALayer* layer);

@implementation UIView (GAViewStyling)

- (NSString *)styleSelector
{
    // Tags identify views within the hierarchy, so we'll use it if we can...
    //
    if ([self tag] > 0)
        return [NSString stringWithFormat:@"#tag-%d", [self tag]];
     
    return [NSString stringWithFormat:@".%@", NSStringFromClass([self class])];
}

- (void)applyStylesWithScriptEngine:(GAScriptEngine *)engine
{
    NSString* selector = [self styleSelector];
    GADebugStr(@"GAViewStyling selector: %@", selector);
    
    id element = [[engine documentObject] querySelector:selector];
    
    if ([element isJavaScriptTrue])
    {
        id cssDeclaration = [[engine windowObject] getComputedStyle:element];    
        [self applyComputedStyles:cssDeclaration];
    }
    
    for (UIView* childView in self.subviews)
    {
        [childView applyStylesWithScriptEngine:engine];
    }
}

- (void)applyComputedStyles:(id)cssDeclaration
{
    // String will be "rgb(r, g, b)" with numbers in base 10
    //
    NSString* backgroundColor = [cssDeclaration valueForKey:@"background-color"];
    self.backgroundColor = [UIColor colorWithCSSColor:backgroundColor];    
    
    NSString* backgroundImage = [cssDeclaration valueForKey:@"background-image"];
    
    // If this view's layer is a CAGradientLayer, we can use a webkit linear gradient
    // -webkit-gradient(<type>, <point>, <point> [, <stop>]*)
    //
    if ([backgroundImage hasPrefix:@"-webkit-gradient(linear,"])
    {
        CAGradientLayer* gradLayer;
        
        if ([self.layer isKindOfClass:[CAGradientLayer class]])
        {
            gradLayer = (CAGradientLayer *)self.layer;
        }
        else
        {
            gradLayer = GAGradientSubLayerForLayer(self.layer);
        }
        
        [gradLayer setValuesWithCSSGradient:backgroundImage];
    }

    NSString* opacity = [cssDeclaration valueForKey:@"opacity"];
    self.alpha = [opacity floatValue];
}

/**
 * Adds (or returns) a gradient sub-layer at position zero in the given layer.
 */
CAGradientLayer* GAGradientSubLayerForLayer (CALayer* layer)
{
    CAGradientLayer* gradLayer = [layer.sublayers objectAtIndex:0];
    
    if (![gradLayer valueForKey:@"GAViewStylingID"])
    {
        gradLayer = [CAGradientLayer layer];
        [gradLayer setValue:@"-webkit-gradient" forKey:@"GAViewStylingID"];
        
        CGRect bounds = [layer bounds];
        [gradLayer setBounds:bounds];
        [gradLayer setPosition:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
        
        [layer insertSublayer:gradLayer atIndex:0];
    }
        
    return gradLayer;
}

@end

#pragma mark -

@implementation UINavigationBar (GAViewStyling)

- (void)applyComputedStyles:(id)cssDeclaration
{
    // It doesn't make sense to set self.backgroundColor for toolbar views. The tintColor is what matters.
    //
    NSString* backgroundColor = [cssDeclaration valueForKey:@"background-color"];
    self.tintColor = [UIColor colorWithCSSColor:backgroundColor];    
}

@end

#pragma mark -

@implementation UISearchBar (GAViewStyling)

- (void)applyComputedStyles:(id)cssDeclaration
{
    NSString* backgroundColor = [cssDeclaration valueForKey:@"background-color"];
    self.tintColor = [UIColor colorWithCSSColor:backgroundColor];    
}

@end

#pragma mark -

@implementation UIToolbar (GAViewStyling)

- (void)applyComputedStyles:(id)cssDeclaration
{
    NSString* backgroundColor = [cssDeclaration valueForKey:@"background-color"];
    self.tintColor = [UIColor colorWithCSSColor:backgroundColor];    
}

@end

#pragma mark -

@implementation UIImageView (GAViewStyling)

- (void)applyComputedStyles:(id)cssDeclaration
{
    [super applyComputedStyles:cssDeclaration];
    
    NSString* backgroundImage = [cssDeclaration valueForKey:@"background-image"];
    
    if ([backgroundImage isEqualToString:@"none"] || ![backgroundImage hasPrefix:@"url("])
        return;
    
    self.image = [UIImage imageWithCSSURL:backgroundImage];
    
    // Default for background images is to put them in the top left (background-position: 0% 0%)
    //
    NSString* backgroundPos = [cssDeclaration valueForKey:@"background-position"];
    
    if ([backgroundPos isEqualToString:@"0% 0%"])
        self.contentMode = UIViewContentModeTopLeft;
    else if ([backgroundPos isEqualToString:@"50% 50%"])
        self.contentMode = UIViewContentModeCenter;
    else if ([backgroundPos isEqualToString:@"50% 100%"])
        self.contentMode = UIViewContentModeBottom;
    
    // Note that we ignore background-repeat in this UIImageView category since it doesn't support that.
}

@end

#pragma mark -

@implementation UILabel (GAViewStyling)

- (NSString *)styleSelector
{
    if ([self tag] > 0)
        return [NSString stringWithFormat:@"#tag-%d", [self tag]];

    // For standard labels, use the parent view's class, since label styling is going to be tied to the view
    // that hosts the labels. If this is a custom UILabel subclass, we'll use that class name instead.
    //
    Class clazz = ([self class] == [UILabel class]) ? [self.superview class] : [self class];
    return [NSString stringWithFormat:@".%@", NSStringFromClass(clazz)];
}

- (void)applyComputedStyles:(id)cssDeclaration
{
    // Text Font
    self.font = [UIFont fontWithCSSDeclaration:cssDeclaration];

    // Text Color
    NSString* color = [cssDeclaration valueForKey:@"color"];
    self.textColor = [UIColor colorWithCSSColor:color];
    
    // Text Alignment
    // UIKit doesn't support "justified"
    //
    NSString* textAlign = [cssDeclaration valueForKey:@"text-align"];
    
    if ([textAlign isEqualToString:@"left"])
        self.textAlignment = UITextAlignmentLeft;
    else if ([textAlign isEqualToString:@"center"])
        self.textAlignment = UITextAlignmentCenter;
    else if ([textAlign isEqualToString:@"right"])
        self.textAlignment = UITextAlignmentRight;
	
	// Text Overflow
	NSString* textOverflow = [cssDeclaration valueForKey:@"text-overflow"];
	
	if ([textOverflow isEqualToString:@"ellipsis"])
		self.lineBreakMode = UILineBreakModeTailTruncation;
	else if ([textOverflow isEqualToString:@"clip"])
		self.lineBreakMode = UILineBreakModeClip;
    
    // Text Shadow
    NSString* textShadow = [cssDeclaration valueForKey:@"text-shadow"];
    
    if ([textShadow isEqualToString:@"none"])
        return;
    
    self.shadowColor = [UIColor colorWithCSSColor:textShadow];

    // Compute the shadow offset, which comes after the color
    // UIKit doesn't support the "blur" length, so it will be ignored
    NSRange xRange = [textShadow rangeOfString:@") "];
    self.shadowOffset = GASizeFromCSSLengths([textShadow substringFromIndex:xRange.location + 2]);
}

@end

#pragma mark -

@implementation UITableView (GAViewStyling)

- (void)applyComputedStyles:(id)cssDeclaration
{    
    [super applyComputedStyles:cssDeclaration];
    
    // Border (Separator) Color. We use "top" because it's the first color in TRBL.
    //
    NSString* borderColor = [cssDeclaration valueForKey:@"border-top-color"];
    self.separatorColor = [UIColor colorWithCSSColor:borderColor];
    
    // Border (Separator) Style. We use "double" to indicate the etched look
    //
    NSString* borderStyle = [cssDeclaration valueForKey:@"border-top-style"];
    
    if ([borderStyle isEqualToString:@"none"])
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    else if ([borderStyle isEqualToString:@"double"])
        self.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
    else
        self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

@end

@implementation UITableViewCell (GAViewStyling)

- (void)applyComputedStyles:(id)cssDeclaration
{
    if (self.backgroundView)    // Don't apply background styles to this view
        return;
    
    [super applyComputedStyles:cssDeclaration];
}

@end
