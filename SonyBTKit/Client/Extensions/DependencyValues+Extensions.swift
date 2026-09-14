import Dependencies
import DependenciesMacros

extension DependencyValues {
    @DependencyEntry(liveValue: HeadphonesClient())
    public var headphonesClient: any HeadphonesClientProtocol = HeadphonesTestClient()
}
