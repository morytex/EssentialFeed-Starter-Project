//
//  ManagedCache.swift
//  EssentialFeed
//
//  Created by Alessandro Moryta Suemasu on 16/04/26.
//

import CoreData

@objc(ManagedCache)
final class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

extension ManagedCache {
    var localFeed: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
    }

    static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try find(in: context).map(context.delete)
        return ManagedCache(context: context)
    }

    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        guard let entityName = entity().name else { return nil }
        let request = NSFetchRequest<ManagedCache>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
}
