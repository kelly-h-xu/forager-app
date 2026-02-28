//
//  IntroView.swift
//  Forager
//
//  Created by Kelly Xu on 2/26/26.
//

import SwiftUI

struct IntroView: View {
    @State private var currentPage = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                IntroPage(
                    image: "forager-char-default",
                    title: "Welcome to Forager",
                    subtitle: "Helping you identify edible wild plants, and avoid harmful ones!*"
                ).tag(0)
                
                IntroPage(
                    image: "heart.fill",
                    title: "Forager will help you see...",
                    subtitle: """
                    Which plants we recognize as edible, and which ones we don’t, using computer vision.
                    """
                ).tag(1)
                
                IntroPage(
                    image: "bolt.fill",
                    title: "...But sight isn’t enough!",
                    subtitle: """
                        
                    Sometimes, Forager will ask you to select other features of the plant, including smell and touch.
                    
                    These features could be the difference between a delicious snack, and a regretful one!
                    """
                ).tag(2)
                
                IntroPage(
                    image: "checkmark.seal.fill",
                    title: "It’s almost time to start foraging!",
                    subtitle:
                    """
                    Before we do, make sure you know the common tells of poisonous plants.
                    
                    Consuming a poisonous plant can be deadly. Never consume a plant without being 100% sure of its identity.
                    """
                ).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // hide default dots
            
            // Custom dot indicator
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? Color("Evergreen") : Color.gray.opacity(0.4))
                            .frame(width: index == currentPage ? 10 : 8,
                                   height: index == currentPage ? 10 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
            }
            .padding(.bottom, UIScreen.main.bounds.height * 0.1)

            if currentPage == 0 {
                Text("*This app is for educational purposes only. Never consume wild plants without 100% certainty of their identity.")
                    .font(Font.custom("Nunito", size: UIScreen.main.bounds.width < 600 ? 12 : 24))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, UIScreen.main.bounds.width * 0.1)
                    .padding(.vertical, 20)
            }
            // Show buttons only on the last page
            if currentPage == 3 {
                HStack(spacing: 20) {
                    //the buttons don't work right now 
                    NavigationLink(destination: CameraView()) { //close the intro screen
                        Text("No Thanks")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("TealMidnight"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: FieldGuideView()) { //show the field guide on top of the camera 
                        Text("View the Field Guide")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Evergreen"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, UIScreen.main.bounds.height * 0.05)
            }
        }
    }
}

struct IntroPage: View {
    let image: String
    let title: String
    let subtitle: String
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < 600 // iPhone vs iPad/Mac
            
            VStack(spacing: 0) {
                // Top portion — colored with image
                ZStack {
                    Color("WhiteAsparagus")
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .padding(geo.size.width * 0.08)
                }
                .frame(height: geo.size.height * 7/16)
                
                // Bottom portion — text
                VStack(spacing: geo.size.height * 0.01) {
                    Text(title)
                        .font(Font.custom("Nunito", size: isCompact ? 28 : 64))
                        .bold()
                        .foregroundStyle(Color("TealMidnight"))
                        .multilineTextAlignment(.center)
                        .padding(.top, geo.size.height * 0.04)
                        .padding(.horizontal, geo.size.width * 0.05)
                    Text(subtitle)
                        .font(Font.custom("Nunito", size: isCompact ? 14 : 28))
                        .foregroundStyle(Color("TealMidnight"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, geo.size.width * (isCompact ? 0.08 : 0.15))
                        .padding(.vertical, geo.size.height * 0.015)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

#Preview {
    IntroView()
}
