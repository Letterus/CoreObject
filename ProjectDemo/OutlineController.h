#import <Cocoa/Cocoa.h>
#import "OutlineItem.h"
#import "Document.h"

@interface OutlineController : NSWindowController
{
  IBOutlet NSOutlineView *outlineView;
  Document *doc; // weak ref
}

- (id)initWithDocument: (id)document;

- (Document*)projectDocument;
- (OutlineItem*)rootObject;

- (IBAction) addItem: (id)sender;
- (IBAction) addChildItem: (id)sender;
- (IBAction) shiftLeft: (id)sender;
- (IBAction) shiftRight: (id)sender;

- (IBAction) shareWith: (id)sender;

@end
