// Views/Main/PerfilView.swift - VERSÃO ATUALIZADA
import SwiftUI
import FirebaseAuth

struct PerfilView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var logoutError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header com informações do usuário
                if let user = authViewModel.user {
                    VStack(spacing: 12) {
                        userAvatarView
                        
                        Text(user.username.isEmpty ? "Usuário" : user.username)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                
                // Lista de opções
                List {
                    Section("Conta") {
                        NavigationLink {
                            if let user = authViewModel.user {
                                EditProfileView(user: user)
                            }
                        } label: {
                            Label("Editar Perfil", systemImage: "person.crop.circle")
                        }
                        
                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            Label("Alterar Senha", systemImage: "lock.circle")
                        }
                    }
                    
                    Section("App") {
                        NavigationLink {
                            SobreView()
                        } label: {
                            Label("Sobre", systemImage: "info.circle")
                        }
                        
                        Button {
                            abrirAppStore()
                        } label: {
                            Label("Avaliar na App Store", systemImage: "star.circle")
                        }
                    }
                    
                    Section {
                        NavigationLink {
                            DeleteAccountView()
                                .environmentObject(authViewModel)
                        } label: {
                            Spacer()
                            Label("Excluir Conta", systemImage: "trash.circle")
                                .foregroundColor(.red)
                        }
                    
                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Saindo...")
                                        .padding(.leading, 8)
                                } else {
                                    Label("Sair da Conta", systemImage: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                }
                                Spacer()
                            }
                        }
                        .disabled(authViewModel.isLoading)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Perfil")
            .alert("Sair da Conta", isPresented: $showLogoutAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Sair", role: .destructive) {
                    realizarLogout()
                }
            } message: {
                Text("Tem certeza que deseja sair da sua conta?")
            }
            .alert("Erro ao Sair", isPresented: .constant(logoutError != nil)) {
                Button("OK") {
                    logoutError = nil
                }
            } message: {
                if let error = logoutError {
                    Text(error)
                }
            }
        }
    }
    
    private var userAvatarView: some View {
        Group {
            if let user = authViewModel.user, !user.username.isEmpty {
                Text(user.username.prefix(1).uppercased())
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.9), .blue.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func realizarLogout() {
        print("🟡 Iniciando logout...")
        authViewModel.signOut()
        
        // Verificar se o logout foi bem-sucedido após um delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if Auth.auth().currentUser == nil {
                print("🟢 Logout confirmado - usuário não está mais autenticado")
            } else {
                print("🔴 Logout falhou - usuário ainda autenticado")
                logoutError = "Não foi possível sair da conta. Tente novamente."
            }
        }
    }
    
    private func abrirAppStore() {
        // URL genérica - substitua pelo URL do seu app na App Store
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
            UIApplication.shared.open(url)
        }
    }
}

// Manter a SobreView como estava
struct SobreView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Trainar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Versão MT ALTA")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Seu app de treinos pessoal")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Text("Desenvolvido com muita raiva e bugs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Sobre")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PerfilView()
        .environmentObject(AuthViewModel())
}
