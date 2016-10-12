//: # Prelude

import Cocoa

//: # Case Study: Wrapping Core Image {#wrapping-core-image}
//: ## The Filter Type

typealias Filter = (CIImage) -> CIImage

//: ## Building Filters
//: ### Blur

func blur(_ radius: Double) -> Filter {
    return { image in
		let parameters: [String: Any] = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ]
        guard let filter = CIFilter(name: "CIGaussianBlur",
            withInputParameters: parameters) else { fatalError() }
        guard let outputImage = filter.outputImage else { fatalError() }
        return outputImage
    }
}

//: ### Color Overlay

func colorGenerator(_ color: NSColor) -> Filter {
    return { _ in
        guard let c = CIColor(color: color) else { fatalError() }
        let parameters = [kCIInputColorKey: c]
        guard let filter = CIFilter(name: "CIConstantColorGenerator",
            withInputParameters: parameters) else { fatalError() }
        guard let outputImage = filter.outputImage else { fatalError() }
        return outputImage
    }
}


func compositeSourceOver(_ overlay: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: image,
            kCIInputImageKey: overlay
        ]
        guard let filter = CIFilter(name: "CISourceOverCompositing",
            withInputParameters: parameters) else { fatalError() }
        guard let outputImage = filter.outputImage else { fatalError() }
        let cropRect = image.extent
        return outputImage.cropping(to: cropRect)
    }
}


func colorOverlay(_ color: NSColor) -> Filter {
    return { image in
        let overlay = colorGenerator(color)(image)
        return compositeSourceOver(overlay)(image)
    }
}

//: ## Composing Filters

let url = NSURL(string: "http://www.objc.io/images/covers/16.jpg")!
let image = CIImage(contentsOf: url as URL)!


let blurRadius = 5.0
let overlayColor = NSColor.red.withAlphaComponent(0.2)
let blurredImage = blur(blurRadius)(image)
let overlaidImage = colorOverlay(overlayColor)(blurredImage)

//: ### Function Composition

let result = colorOverlay(overlayColor)(blur(blurRadius)(image))


func composeFilters(_ filter1: @escaping Filter, _ filter2: @escaping Filter) -> Filter {
    return { image in filter2(filter1(image)) }
}


let myFilter1 = composeFilters(blur(blurRadius), colorOverlay(overlayColor))
let result1 = myFilter1(image)

precedencegroup CustomPrecedence {
	associativity: left
}

infix operator >>>: CustomPrecedence

func >>> (filter1: @escaping Filter, filter2: @escaping Filter) -> Filter {
    return { image in filter2(filter1(image)) }
}


let myFilter2 = blur(blurRadius) >>> colorOverlay(overlayColor)
let result2 = myFilter2(image)

//: ## Theoretical Background: Currying

func add1(_ x: Int, _ y: Int) -> Int {
    return x + y
}


func add2(_ x: Int) -> ((Int) -> Int) {
    return { y in return x + y }
}


add1(1, 2)
add2(1)(2)

// This function declaration syntax will no longer work. So here is a compiler error.
func add3(x: Int)(_ y: Int) -> Int {
    return x + y
}

// Error
add3(1)(2)

//: ## Discussion
