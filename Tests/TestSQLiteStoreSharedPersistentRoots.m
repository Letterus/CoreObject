#import "TestCommon.h"
#import "COItem.h"
#import "COPath.h"
#import "COSearchResult.h"

/**
 * Tests two persistent roots sharing the same backing store behave correctly
 */
@interface TestSQLiteStoreSharedPersistentRoots : SQLiteStoreTestCase <UKTest>
{
    COPersistentRootInfo *prootA;
    COPersistentRootInfo *prootB;
	
	int64_t prootAChangeCount;
	int64_t prootBChangeCount;
}
@end

@implementation TestSQLiteStoreSharedPersistentRoots

// Embdedded item UUIDs
static ETUUID *rootUUID;

+ (void) initialize
{
    if (self == [TestSQLiteStoreSharedPersistentRoots class])
    {
        rootUUID = [[ETUUID alloc] init];
    }
}

- (COItemGraph *) prooBitemTree
{
    COMutableItem *rootItem = [[COMutableItem alloc] initWithUUID: rootUUID];
    [rootItem setValue: @"prootB" forAttribute: @"name" type: kCOTypeString];
    
    return [COItemGraph itemGraphWithItemsRootFirst: A(rootItem)];
}

- (COItemGraph *) prootAitemTree
{
    COMutableItem *rootItem = [[COMutableItem alloc] initWithUUID: rootUUID];
    [rootItem setValue: @"prootA" forAttribute: @"name" type: kCOTypeString];
    
    return [COItemGraph itemGraphWithItemsRootFirst: A(rootItem)];
}

- (id) init
{
    SUPERINIT;
    
    COStoreTransaction *txn = [[COStoreTransaction alloc] init];
    prootA = [txn createPersistentRootWithInitialItemGraph: [self prootAitemTree]
													  UUID: [ETUUID UUID]
												branchUUID: [ETUUID UUID]
										  revisionMetadata: nil];

	ETUUID *prootBBranchUUID = [ETUUID UUID];
	
	prootB = [txn createPersistentRootWithUUID: [ETUUID UUID]
									branchUUID: [ETUUID UUID]
							  parentBranchUUID: nil
										isCopy: YES
							   initialRevision: [[prootA currentBranchInfo] currentRevisionID]];
    
    CORevisionID *prootBRev = [CORevisionID revisionWithPersistentRootUUID: [prootB UUID]
															  revisionUUID: [ETUUID UUID]];
	
	[txn writeRevisionWithModifiedItems: [self prooBitemTree]
						   revisionUUID: [prootBRev revisionUUID]
							   metadata: nil
					   parentRevisionID: [[[prootA currentBranchInfo] currentRevisionID] revisionUUID]
				  mergeParentRevisionID: nil
					 persistentRootUUID: [prootB UUID]
							 branchUUID: prootBBranchUUID];

    [txn setCurrentRevision: [prootBRev revisionUUID]
				 headRevision: [prootBRev revisionUUID]
	                forBranch: [prootB currentBranchUUID]
	         ofPersistentRoot: [prootB UUID]];

    prootB.currentBranchInfo.currentRevisionID = prootBRev;
    
	prootAChangeCount = [txn setOldTransactionID: -1 forPersistentRoot: [prootA UUID]];
	prootBChangeCount = [txn setOldTransactionID: -1 forPersistentRoot: [prootB UUID]];
	
    UKTrue([store commitStoreTransaction: txn]);
	
    return self;
}


- (void) testBasic
{
    UKNotNil(prootA);
    UKNotNil(prootB);
    
    CORevisionInfo *prootARevInfo = [store revisionInfoForRevisionID: [prootA currentRevisionID]];
    CORevisionInfo *prootBRevInfo = [store revisionInfoForRevisionID: [prootB currentRevisionID]];
    
    UKNotNil(prootARevInfo);
    UKNotNil(prootBRevInfo);
    
    UKObjectsNotEqual([prootARevInfo revisionID], [prootBRevInfo revisionID]);
    UKObjectsEqual([prootARevInfo revisionID], [prootBRevInfo parentRevisionID]);
    
    UKObjectsEqual([self prootAitemTree], [store itemGraphForRevisionID: [prootA currentRevisionID]]);
    UKObjectsEqual([self prooBitemTree], [store itemGraphForRevisionID: [prootB currentRevisionID]]);
}

- (void) testDeleteOriginalPersistentRoot
{
	{
		COStoreTransaction *txn = [[COStoreTransaction alloc] init];
		[txn deletePersistentRoot: [prootA UUID]];
		prootAChangeCount = [txn setOldTransactionID: prootAChangeCount forPersistentRoot: [prootA UUID]];
		UKTrue([store commitStoreTransaction: txn]);
	}

    UKTrue([store finalizeDeletionsForPersistentRoot: [prootA UUID] error: NULL]);

    UKNil([store persistentRootInfoForUUID: [prootA UUID]]);
    
    // prootB should be unaffected. Both commits should be accessible.
    
    UKNotNil([store persistentRootInfoForUUID: [prootB UUID]]);

    UKObjectsEqual([self prootAitemTree], [store itemGraphForRevisionID: [prootA currentRevisionID]]);
    UKObjectsEqual([self prooBitemTree], [store itemGraphForRevisionID: [prootB currentRevisionID]]);
}

- (void) testDeleteCopiedPersistentRoot
{
	{
		COStoreTransaction *txn = [[COStoreTransaction alloc] init];
		[txn deletePersistentRoot: [prootB UUID]];
		prootBChangeCount = [txn setOldTransactionID: prootBChangeCount forPersistentRoot: [prootB UUID]];
		UKTrue([store commitStoreTransaction: txn]);
	}

    UKTrue([store finalizeDeletionsForPersistentRoot: [prootB UUID] error: NULL]);
    
    UKNil([store persistentRootInfoForUUID: [prootB UUID]]);
    
    // prootA should be unaffected. Only the first commit should be accessible.
    
    UKNotNil([store persistentRootInfoForUUID: [prootA UUID]]);
    
    UKObjectsEqual([self prootAitemTree], [store itemGraphForRevisionID: [prootA currentRevisionID]]);
    UKNil([store itemGraphForRevisionID: [prootB currentRevisionID]]);
}

@end
