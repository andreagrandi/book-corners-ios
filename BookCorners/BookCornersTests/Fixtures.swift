//
//  Fixtures.swift
//  BookCornersTests
//
//  Created by Andrea Grandi on 11/03/26.
//

import Foundation

enum Fixtures {
    static let libraryJSON = """
    {
        "id": 1,
        "slug": "little-free-library-berlin",
        "name": "Little Free Library Berlin",
        "description": "A cozy book corner near the park",
        "photo_url": "https://example.com/photo.jpg",
        "thumbnail_url": "https://example.com/thumb.jpg",
        "lat": 52.52,
        "lng": 13.405,
        "address": "Alexanderplatz 1",
        "city": "Berlin",
        "country": "DE",
        "postal_code": "10178",
        "wheelchair_accessible": "yes",
        "capacity": 30,
        "is_indoor": false,
        "is_lit": true,
        "website": "https://example.com",
        "contact": "info@example.com",
        "source": "user",
        "operator": "Book Club Berlin",
        "brand": "",
        "created_at": "2025-06-15T14:30:00Z"
    }
    """

    static let libraryNullFieldsJSON = """
    {
        "id": 2,
        "slug": "park-books-munich",
        "name": "Park Books Munich",
        "description": "",
        "photo_url": "",
        "thumbnail_url": "",
        "lat": 48.1351,
        "lng": 11.582,
        "address": "Marienplatz 1",
        "city": "Munich",
        "country": "DE",
        "postal_code": "80331",
        "wheelchair_accessible": "",
        "capacity": null,
        "is_indoor": null,
        "is_lit": null,
        "website": "",
        "contact": "",
        "source": "import",
        "operator": "",
        "brand": "",
        "created_at": "2025-08-01T10:00:00Z"
    }
    """

    static let libraryListJSON = """
    {
        "items": [
            {
                "id": 1,
                "slug": "little-free-library-berlin",
                "name": "Little Free Library Berlin",
                "description": "A cozy book corner near the park",
                "photo_url": "https://example.com/photo.jpg",
                "thumbnail_url": "https://example.com/thumb.jpg",
                "lat": 52.52,
                "lng": 13.405,
                "address": "Alexanderplatz 1",
                "city": "Berlin",
                "country": "DE",
                "postal_code": "10178",
                "wheelchair_accessible": "yes",
                "capacity": 30,
                "is_indoor": false,
                "is_lit": true,
                "website": "https://example.com",
                "contact": "info@example.com",
                "source": "user",
                "operator": "Book Club Berlin",
                "brand": "",
                "created_at": "2025-06-15T14:30:00Z"
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

    static let latestLibrariesJSON = """
    {
        "items": [
            {
                "id": 1,
                "slug": "little-free-library-berlin",
                "name": "Little Free Library Berlin",
                "description": "A cozy book corner near the park",
                "photo_url": "https://example.com/photo.jpg",
                "thumbnail_url": "https://example.com/thumb.jpg",
                "lat": 52.52,
                "lng": 13.405,
                "address": "Alexanderplatz 1",
                "city": "Berlin",
                "country": "DE",
                "postal_code": "10178",
                "wheelchair_accessible": "yes",
                "capacity": 30,
                "is_indoor": false,
                "is_lit": true,
                "website": "https://example.com",
                "contact": "info@example.com",
                "source": "user",
                "operator": "Book Club Berlin",
                "brand": "",
                "created_at": "2025-06-15T14:30:00Z"
            }
        ]
    }
    """

    static let tokenPairJSON = """
    {
        "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test.access",
        "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test.refresh"
    }
    """

    static let userJSON = """
    {
        "id": 42,
        "username": "booklover",
        "email": "booklover@example.com"
    }
    """

    static let statisticsJSON = """
    {
        "total_approved": 1523,
        "total_with_image": 987,
        "top_countries": [
            {
                "country_code": "DE",
                "country_name": "Germany",
                "flag_emoji": "🇩🇪",
                "count": 450
            },
            {
                "country_code": "US",
                "country_name": "United States",
                "flag_emoji": "🇺🇸",
                "count": 312
            }
        ],
        "cumulative_series": [
            {
                "period": "2025-01",
                "cumulative_count": 800
            },
            {
                "period": "2025-06",
                "cumulative_count": 1523
            }
        ],
        "granularity": "monthly"
    }
    """

    static let apiErrorJSON = """
    {
        "message": "Invalid credentials",
        "details": {
            "username": "Not found"
        }
    }
    """

    static let rateLimitErrorJSON = """
    {
        "message": "Too many requests",
        "details": {
            "retry_after": "30"
        }
    }
    """
}
