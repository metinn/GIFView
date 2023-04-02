import SwiftUI

class GIFViewViewModel: ObservableObject {
    @Published var image: UIImage?
    private var parser: GIFParser?
    
    init(name: String) {
        Task {
            self.parser = try await GIFParser(name: name)
        }
    }
    
    init(data: Data) {
        self.parser = try? GIFParser(data: data)
    }
    
    func loadGIF() async {
        do {
            try await parser?.loadNextImage()

            self.showNext()

        } catch let err {
            print("ERROR: Parser error \(err.localizedDescription)")
        }
    }
    
    func showNext() {
        guard let (image, delay) = self.parser?.getCurrentImageAndDelay() else { return }

        DispatchQueue.main.async {
            self.image = image
        }

        Task { try await parser?.loadNextImage() }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.showNext()
        }
    }
}

struct GIFView: View {
    @StateObject var vm: GIFViewViewModel
    
    init(name: String) {
        self._vm = StateObject(wrappedValue: GIFViewViewModel(name: name))
    }
    
    init(data: Data) {
        self._vm = StateObject(wrappedValue: GIFViewViewModel(data: data))
    }
    
    var body: some View {
        if let im = vm.image {
            Image(uiImage: im)
        } else {
            Color.white
                .onAppear {
                    Task { await vm.loadGIF() }
                }
        }
    }
}
