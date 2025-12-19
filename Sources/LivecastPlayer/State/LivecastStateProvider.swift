import Combine

public protocol LivecastStateReader: AnyObject {
    var currentPublisher: AnyPublisher<LivecastState, Never> { get }
    var current: LivecastState { get }
}

protocol LivecastStateWriter: LivecastStateReader {
    func setState(_ state: LivecastState)
}

final class LivecastStateProvider: LivecastStateWriter {
    private var stateSubject = CurrentValueSubject<LivecastState, Never>(
        LivecastState(
            positionInfo: LivecastPositionInfo(),
            mediaInfo: LivecastMediaInfo(),
            playbackState: .stopped,
            error: nil
        )
    )

    var currentPublisher: AnyPublisher<LivecastState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var current: LivecastState {
        stateSubject.value
    }

    func setState(_ state: LivecastState) {
        stateSubject.send(state)
    }
}
