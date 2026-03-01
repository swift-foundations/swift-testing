extension Showcase {
    public struct User: Sendable {
        public var name: String
        public var email: String
        public var role: Role

        public init(name: String, email: String, role: Role = .member) {
            self.name = name
            self.email = email
            self.role = role
        }
    }
}

extension Showcase.User {
    public enum Role: String, Sendable {
        case admin
        case member
        case guest
    }
}

extension Showcase.User: CustomStringConvertible {
    public var description: String {
        """
        User: \(name)
        Email: \(email)
        Role: \(role.rawValue)
        """
    }
}
