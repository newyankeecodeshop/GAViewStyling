# Overview

One of the neat parts about having a library, GAJavaScript, that makes it easier to access JavaScript is that using WebKit functionality becomes easier. One of those WebKit features is the CSS engine. GAViewStyling classes provide a means to drive UIView cosmetic properties via CSS declarations in an HTML document.

## How it works

Using the UIWebView connected to a GAScriptEngine, load an HTML document that contains HTML markup and CSS. (The stylesheet could be embedded in the HTML, or external.) The HTML markup must provide one or more elements for each style that will be applied. The view styling engine does the following:

1. Starting with a UIView instance, determine the selector uses to query for a DOM element that represents the view. Currently, there are two kinds of selectors used. The class selector (e.g. .UITableView) is used when the view has no tag - the name of the Objective-C class is used as the "class" name. If the view has a nonzero tag, an ID selector (e.g. #tag-3000) is used. This allows you to create styles for specific UIViews.
2. Query the DOM for an element matching the selector.
3. If an element is found, call `window.getComputedStyle()` with that element.
4. Use the resulting CSSStyleDeclaration object to populate UIView properties such as backgroundColor, tintColor, font, etc.
5. Continue processing all of the view's subviews.

GAViewStyling uses a category on UIView and many UIKit view classes. Your own custom view classes can implement methods in the category to change the behavior or apply CSS style information to your custom view properties.

## Example

The "Theme Explorer" app in the /Samples folder shows how CSS can style various UIKit views and controls. It's built on the Apple "UICatalog" SDK sample, and it applies various (somewhat ugly) "themes" to the table views and various controls. It shows how you can change the overall styles "on the fly", while the app is running.

In the "styles.html" file, notice how there are DIV tags in the body that have one or more classes set. This is essential so that the view styling code has an element to which styles can be applied. Also, you can just open the file in Safari to get a "preview" of what the styling will look like.

When the Theme button changes from red to blue, it's just replacing the class on the BODY tag. This makes it easy to swap out entire style sets without having to write much code.

## Categories

Even if the view styling code is not what you need, you might find some of the categories which can create colors, fonts and gradients from CSS-style strings.

	// Create a UIColor
	UIColor* color = [UIColor colorWithCSSColor:@"rgb(255, 128, 0)"];
	
	// Create a UIFont
    NSDictionary* decl = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Verdana", @"font-family",
                          @"24px", @"font-size",
                          @"bold", @"font-weight", nil];
    UIFont* font = [UIFont fontWithCSSDeclaration:decl];
    
    // Create a gradient layer
    NSString* cssGradient = @"-webkit-gradient(linear, 0% 0%, 0% 100%, from(rgba(217, 217, 217, 0)), to(rgba(0, 0, 0, 0.5)))";

    CAGradientLayer* layer = [CAGradientLayer layer];
    [layer setValuesWithCSSGradient:cssGradient];

The above code uses the categories defined in `GAViewStyling.h`.

