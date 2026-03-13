//
//  SerialNetworkTests.swift
//  BookCornersTests
//
//  Forces all test suites that use MockURLProtocol to run serially,
//  preventing them from overwriting each other's requestHandler.
//

import Testing

@Suite(.serialized) struct SerialNetworkTests {}
