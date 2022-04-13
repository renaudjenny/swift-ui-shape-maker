import SwiftUI

#if os(macOS)
import Quartz
#endif

struct ContentView: View {
    @State private var image: Image? = nil
    @State private var imageOpacity = 1.0
    @State private var code: String = "Code"

    var body: some View {
        VStack {
            HStack {
                Slider(value: $imageOpacity) { Text("Image opacity") }
                Button("Choose an image") { openImagePicker() }
            }
            .padding()
            HStack {
                ZStack {
                    ZStack {
                        DrawingPanel()
                        image?
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(imageOpacity)
                    }
                    .frame(width: 800, height: 800)
                    .padding()
                }
                Text(code).frame(maxWidth: .infinity)
            }
        }
    }

    func openImagePicker() {
        #if os(macOS)
        let pictureTaker = IKPictureTaker.pictureTaker()
        pictureTaker?.runModal()
        pictureTaker?.outputImage().map { image = Image(nsImage: $0) }
        #endif
    }
}

struct DrawingPanel: View {
    var body: some View {
        Color.white
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
