//
//  UIConfirmationDialog.m
//  linphone
//
//  Created by Gautier Pelloux-Prayer on 11/09/15.
//
//

#import "UIConfirmationDialog.h"
#import "PhoneMainView.h"

@implementation UIConfirmationDialog
+ (UIConfirmationDialog *)ShowWithMessage:(NSString *)message
							cancelMessage:(NSString *)cancel
						   confirmMessage:(NSString *)confirm
							onCancelClick:(UIConfirmationBlock)onCancel
					  onConfirmationClick:(UIConfirmationBlock)onConfirm
							 inController:(UIViewController *)controller {
	UIConfirmationDialog *dialog =
		[[UIConfirmationDialog alloc] initWithNibName:NSStringFromClass(self.class) bundle:NSBundle.mainBundle];

	dialog.view.frame = PhoneMainView.instance.mainViewController.view.frame;
	[controller.view addSubview:dialog.view];
	[controller addChildViewController:dialog];

	dialog->onCancelCb = onCancel;
	dialog->onConfirmCb = onConfirm;

	[dialog.titleLabel setText:message];
	if (cancel) {
		[dialog.cancelButton setTitle:cancel forState:UIControlStateNormal];
	}
	if (confirm) {
		[dialog.confirmationButton setTitle:confirm forState:UIControlStateNormal];
	}

    CAGradientLayer *gradient1 = [BackgroundLayer linearGradient];
    gradient1.frame = dialog.confirmationButton.bounds;
    gradient1.startPoint = CGPointMake(0.0,0.0);
    gradient1.endPoint = CGPointMake(1.0,0.0);
    [dialog.confirmationButton.layer insertSublayer:gradient1 atIndex:0];
    
	return dialog;
}

+ (UIConfirmationDialog *)ShowWithMessage:(NSString *)message
							cancelMessage:(NSString *)cancel
						   confirmMessage:(NSString *)confirm
							onCancelClick:(UIConfirmationBlock)onCancel
					  onConfirmationClick:(UIConfirmationBlock)onConfirm {
	return [self ShowWithMessage:message
				   cancelMessage:cancel
				  confirmMessage:confirm
				   onCancelClick:onCancel
			 onConfirmationClick:onConfirm
					inController:PhoneMainView.instance.mainViewController];
}

- (IBAction)onCancelClick:(id)sender {
	[self.view removeFromSuperview];
	[self removeFromParentViewController];
	if (onCancelCb) {
		onCancelCb();
	}
}

- (IBAction)onConfirmationClick:(id)sender {
	[self.view removeFromSuperview];
	[self removeFromParentViewController];
	if (onConfirmCb) {
		onConfirmCb();
	}
}

- (void)dismiss {
	[self onCancelClick:nil];
}
@end
