//
//  ModerationFixtures.swift
//  BookCornersTests
//

import Foundation

extension Fixtures {
    static let moderationSummaryJSON = """
    {
        "pending_libraries_count": 4,
        "open_reports_count": 2,
        "pending_photos_count": 5,
        "total_pending": 11,
        "total_libraries": 350,
        "total_users": 128
    }
    """

    static let moderationLibraryJSON = """
    {
        "id": 42,
        "slug": "florence-via-rosina-15-corner-books",
        "name": "Corner Books",
        "description": "A cozy book-sharing library near the park entrance.",
        "photo_url": "/media/libraries/photos/corner-books.jpg",
        "thumbnail_url": "/media/libraries/thumbnails/corner-books.jpg",
        "lat": 43.7696,
        "lng": 11.2558,
        "address": "Via Rosina 15",
        "city": "Florence",
        "country": "IT",
        "postal_code": "50123",
        "wheelchair_accessible": "",
        "capacity": null,
        "is_indoor": null,
        "is_lit": null,
        "website": "",
        "contact": "",
        "source": "user",
        "operator": "Book Club Florence",
        "brand": "",
        "created_at": "2026-06-15T14:30:00Z",
        "is_favourited": false,
        "status": "pending",
        "rejection_reason": "",
        "created_by": {
            "id": 1,
            "username": "janedoe"
        }
    }
    """

    static let moderationLibraryListJSON = """
    {
        "items": [
            {
                "id": 42,
                "slug": "florence-via-rosina-15-corner-books",
                "name": "Corner Books",
                "description": "A cozy book-sharing library near the park entrance.",
                "photo_url": "/media/libraries/photos/corner-books.jpg",
                "thumbnail_url": "/media/libraries/thumbnails/corner-books.jpg",
                "lat": 43.7696,
                "lng": 11.2558,
                "address": "Via Rosina 15",
                "city": "Florence",
                "country": "IT",
                "postal_code": "50123",
                "wheelchair_accessible": "",
                "capacity": null,
                "is_indoor": null,
                "is_lit": null,
                "website": "",
                "contact": "",
                "source": "user",
                "operator": "Book Club Florence",
                "brand": "",
                "created_at": "2026-06-15T14:30:00Z",
                "is_favourited": false,
                "status": "pending",
                "rejection_reason": "",
                "created_by": {
                    "id": 1,
                    "username": "janedoe"
                }
            }
        ],
        "pagination": {
            "page": 1,
            "page_size": 20,
            "total": 1,
            "total_pages": 1,
            "has_next": false,
            "has_previous": false
        }
    }
    """

    static let moderationReportJSON = """
    {
        "id": 7,
        "library": {
            "id": 42,
            "slug": "florence-via-rosina-15-corner-books",
            "name": "Corner Books",
            "address": "Via Rosina 15",
            "city": "Florence",
            "country": "IT",
            "status": "approved"
        },
        "created_by": {
            "id": 3,
            "username": "reader"
        },
        "reason": "damaged",
        "details": "The door hinge is broken.",
        "photo_url": "/media/reports/photos/report.jpg",
        "status": "open",
        "created_at": "2026-06-16T10:00:00Z"
    }
    """

    static let moderationReportListJSON = """
    {
        "items": [
            {
                "id": 7,
                "library": {
                    "id": 42,
                    "slug": "florence-via-rosina-15-corner-books",
                    "name": "Corner Books",
                    "address": "Via Rosina 15",
                    "city": "Florence",
                    "country": "IT",
                    "status": "approved"
                },
                "created_by": {
                    "id": 3,
                    "username": "reader"
                },
                "reason": "damaged",
                "details": "The door hinge is broken.",
                "photo_url": "/media/reports/photos/report.jpg",
                "status": "open",
                "created_at": "2026-06-16T10:00:00Z"
            }
        ],
        "pagination": {
            "page": 1,
            "page_size": 20,
            "total": 1,
            "total_pages": 1,
            "has_next": false,
            "has_previous": false
        }
    }
    """

    static let moderationPhotoJSON = """
    {
        "id": 12,
        "library": {
            "id": 42,
            "slug": "florence-via-rosina-15-corner-books",
            "name": "Corner Books",
            "address": "Via Rosina 15",
            "city": "Florence",
            "country": "IT",
            "status": "approved"
        },
        "created_by": {
            "id": 3,
            "username": "reader"
        },
        "caption": "Front view",
        "photo_url": "/media/libraries/user_photos/photo.jpg",
        "thumbnail_url": "/media/libraries/user_photos/thumbnails/photo.jpg",
        "status": "pending",
        "created_at": "2026-06-17T11:00:00Z"
    }
    """

    static let moderationPhotoListJSON = """
    {
        "items": [
            {
                "id": 12,
                "library": {
                    "id": 42,
                    "slug": "florence-via-rosina-15-corner-books",
                    "name": "Corner Books",
                    "address": "Via Rosina 15",
                    "city": "Florence",
                    "country": "IT",
                    "status": "approved"
                },
                "created_by": {
                    "id": 3,
                    "username": "reader"
                },
                "caption": "Front view",
                "photo_url": "/media/libraries/user_photos/photo.jpg",
                "thumbnail_url": "/media/libraries/user_photos/thumbnails/photo.jpg",
                "status": "pending",
                "created_at": "2026-06-17T11:00:00Z"
            }
        ],
        "pagination": {
            "page": 1,
            "page_size": 20,
            "total": 1,
            "total_pages": 1,
            "has_next": false,
            "has_previous": false
        }
    }
    """

    static let staffAccessRequiredJSON = """
    {
        "message": "Staff access required."
    }
    """
}
