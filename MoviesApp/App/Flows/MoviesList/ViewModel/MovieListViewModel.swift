// MovieListViewModel.swift
// Copyright © RoadMap. All rights reserved.

import UIKit

protocol MovieListViewModelProtocol {
    var updateViewData: ViewDataHandler<[Movie]>? { get set }
    var getSearchText: (() -> String?)? { get set }
    func start()
    func paginate()
    func searchMovies()
    func showMovies(title: String)
}

final class MovieListViewModel: MovieListViewModelProtocol {
    // MARK: - Public Properties

    var updateViewData: ViewDataHandler<[Movie]>?
    var getSearchText: (() -> String?)?

    // MARK: - Private Properties

    private let startPage = 1
    private var movieAPIService: MovieAPIServiceProtocol
    private lazy var nextPageNumber = startPage {
        didSet {
            if nextPageNumber == startPage { movies.removeAll() }
        }
    }

    private var movies: [Movie] = [] {
        didSet {
            updateViewData?(.data(movies))
        }
    }

    private lazy var moviesCategories: MoviesCategories = .popular {
        didSet {
            nextPageNumber = startPage
            getMoviesPage(moviesCategories.getUrlString(page: nextPageNumber))
        }
    }

    // MARK: - Initialization

    init(movieAPIService: MovieAPIServiceProtocol) {
        self.movieAPIService = movieAPIService
    }

    // MARK: - Public Methods

    func start() {
        updateViewData?(.loading)
        getMoviesPage(moviesCategories.getUrlString(page: startPage))
    }

    func showMovies(title: String) {
        moviesCategories = MoviesCategories(rawValue: title) ?? .popular
    }

    func paginate() {
        if nextPageNumber == -1 { return }
        if let text = getSearchText?() {
            getMoviesPage(Constants.getSearchMoviesURLString(page: nextPageNumber, searchedText: text))
        } else {
            getMoviesPage(moviesCategories.getUrlString(page: nextPageNumber))
        }
    }

    func searchMovies() {
        nextPageNumber = startPage
        if let text = getSearchText?() {
            getMoviesPage(Constants.getSearchMoviesURLString(page: nextPageNumber, searchedText: text))
        } else {
            getMoviesPage(moviesCategories.getUrlString(page: startPage))
        }
    }

    // MARK: - Private Methods

    private func getMoviesPage(_ urlString: String) {
        movieAPIService.getDecodable(urlString: urlString, to: MoviesListPage.self) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(page):
                guard let movies = page?.results else {
                    self.updateViewData?(.noData)
                    return
                }
                self.movies.append(contentsOf: movies)
                self.setNextPageNumber(page)
            case let .failure(error):
                self.updateViewData?(.error(error))
            }
        }
    }

    private func setNextPageNumber(_ page: MoviesListPage?) {
        guard
            let currentPageNumber = page?.page,
            let totalPages = page?.totalPages,
            currentPageNumber < totalPages
        else {
            nextPageNumber = -1
            return
        }
        nextPageNumber = currentPageNumber + 1
    }
}