// Views/Main/PerfilView.swift
import SwiftUI
import FirebaseAuth

struct PerfilView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var logoutError: String?
    
    var body: some View {
        NavigationStack { // Mudado para NavigationStack para melhor compatibilidade
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
                    
                    Section("Profissional") {
                                            // Link para o FORMULÁRIO (Para quem quer virar profissional)
                                            // Só mostra se ele AINDA NÃO É profissional
                                            if let user = authViewModel.user, !user.isHealthProfessional {
                                                NavigationLink {
                                                    SolicitarProfissionalView() // View do Formulário
                                                } label: {
                                                    Label("Seja um Profissional", systemImage: "checkmark.seal.fill")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            
                                            // Link para o PAINEL (Para quem JÁ É profissional)
                                            // Só aparece se isHealthProfessional for true
                                            if let user = authViewModel.user, user.isHealthProfessional {
                                                NavigationLink {
                                                    ProfissionalView() // View do Dashboard (Criar Treino)
                                                } label: {
                                                    Label("Painel do Personal", systemImage: "dumbbell.fill")
                                                        .foregroundColor(.purple)
                                                }
                                            }
                                        }
                    
                    Section("App") {
                        NavigationLink {
                            SobreView()
                        } label: {
                            Label("Sobre", systemImage: "info.circle")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Saindo...")
                                        .padding(.leading, 8)
                                } else {
                                    Label("Sair da Conta", systemImage: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                }
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
            .onAppear {
                        // ADICIONE ISSO: Força a atualização dos dados toda vez que abrir o perfil
                        Task {
                            await authViewModel.refreshUserData()
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
        authViewModel.signOut()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if Auth.auth().currentUser == nil {
                print("🟢 Logout confirmado")
            } else {
                logoutError = "Não foi possível sair da conta. Tente novamente."
            }
        }
    }
    
    }

struct SobreView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Trainar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Versão 1.3")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Seu app de treinos pessoal")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("-Atualizações\n-Função profissional funcionado\n-Melhorias no design\n-Conteudos anexados a db\n")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Futuras atualizações")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("-Menu exclusivo para profissionais\n-Analize de progresso dinamica\n-Outros recursos")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            
            Text("Desenvolvido com dedicaçãoe com muitos bugs")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Sobre")
        .navigationBarTitleDisplayMode(.inline)
    }
}
