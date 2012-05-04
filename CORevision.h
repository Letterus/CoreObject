#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class COStore;

/** 
 * @group Store
 * @abstract A revision represents a commit in the store history.
 *
 * A revision corresponds to various changes, that were committed at the same 
 * time and belong to a single root object and its inner objects. See 
 * -[COStore finishCommit]. 
 *
 * -changedObjectUUIDs and -valuesAndPropertiesForObjectUUID: can be used to 
 * retrieve the committed changes. 
 *
 * CORevision adopts the collection protocol and its content is a record 
 * collection where each CORecord represents a changed object whose properties 
 * are:
 *
 * <deflist>
 * <item>objectUUID</item><desc>The changed object UUID</desc>
 * <item>properties</item><desc>The properties changed in the object</desc>
 * </deflist>
 */
@interface CORevision : NSObject <ETCollection>
{
	COStore *store;
	int64_t revisionNumber;
	int64_t baseRevisionNumber;
}

/** @taskunit Store */

/** 
 * Returns the store to which the revision and its changed objects belongs to. 
 */
- (COStore *)store;

/** @taskunit History Properties and Metadata */

/** 
 * Returns the revision number.
 *
 * This number shouldn't be used to uniquely identify the revision, unlike -UUID. 
 */
- (int64_t)revisionNumber;

/**
 * The revision upon which this one is based i.e. the main previous revision. 
 * 
 * This is nil when this is the first revision for a root object.
 */
- (CORevision *)baseRevision;


/** 
 * Returns the revision UUID. 
 */
- (ETUUID *)UUID;
/** 
 * Returns the root object UUID involved in the revision. 
 */
- (ETUUID *)objectUUID;
/** 
 * Returns the date at which the revision was committed. 
 */
- (NSDate *)date;
/** 
 * Returns the revision type.
 *
 * e.g. merge, persistent root creation, minor edit, etc.
 * 
 * Note: This type notion is a bit vague currently. 
 */
- (NSString *)type;
/** 
 * Returns the revision short description.
 * 
 * This description is optional.
 */
- (NSString *)shortDescription;
/** 
 * Returns the revision long description.
 * 
 * This description is optional.
 */
- (NSString *)longDescription;

/** 
 * Returns the metadata attached to the revision at commit time. 
 */
- (NSDictionary *)metadata;

/** @taskunit Changes */

/** 
 * Returns the UUIDs that correspond to the objects changed by the revision. 
 */ 
- (NSArray *)changedObjectUUIDs;
/** 
 * Returns a property list listing the changed property values per object in the 
 * revision. 
 */
- (NSDictionary *)valuesAndPropertiesForObjectUUID: (ETUUID *)objectUUID;

/** @taskunit Private */

/** 
 * <init />
 * Initializes and returns a new revision object to represent a precise revision 
 * number in the given store. 
 */
- (id)initWithStore: (COStore *)aStore revisionNumber: (int64_t)anID baseRevisionNumber: (int64_t)baseID;

/**
 * Returns the next revision after this one. 
 *
 * Note that in a non-linear history model, there are multiple <em>next 
 * revisions<em/>. Therefore this method is only meaningful in linear revision 
 * models, where each revision has only one next revision that calls it its 
 * <em>base revision</em>.<br />
 * In the non-linear case, it returns the <em>next revision</em> that has the 
 * highest revision number.
 *
 * See also -baseRevision.
 */
- (CORevision *)nextRevision;
@end
