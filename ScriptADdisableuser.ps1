# Charger le module Active Directory
Import-Module ActiveDirectory

# Charger le module ImportExcel (si nécessaire)
# Import-Module ImportExcel

# Chemin vers le fichier CSV contenant la liste des utilisateurs actifs
$cheminListeUserActifCSV = "\\192.168.30.129\Share\Donnee\listeuseractif.csv"

# Charger le fichier CSV avec les utilisateurs actifs
$ListeUtilisateursActifs = Import-Csv $cheminListeUserActifCSV -Delimiter ";" -Encoding UTF8

# Obtenir tous les noms d'utilisateur actifs en extrayant la partie avant "@" de la colonne "Member Email"
$NomsUtilisateursActifs = $ListeUtilisateursActifs | ForEach-Object {
    $email = $_."Member Email"
    if ($email -match "^(.*?)@") {
        $matches[1]
    } else {
        $email
    }
}

# Charger le fichier CSV avec la liste de tous les utilisateurs d'Active Directory
$cheminADUserCSV = "\\192.168.30.129\Share\Donnee\ADUsers.csv"
$ADUser = Import-Csv $cheminADUserCSV -Delimiter ";" -Encoding UTF8

# Obtenir tous les noms d'utilisateur d'Active Directory depuis la colonne "DisplayName"
$NomsUtilisateursAD = $ADUser | Where-Object { $_.DisplayName -ne "" } | ForEach-Object { $_.DisplayName }

# Créer une liste des utilisateurs à désactiver (présents dans ADUsers.csv mais pas dans listeuseractif.csv)
$UtilisateursADaDesactiver = $NomsUtilisateursAD | Where-Object { $_ -notin $NomsUtilisateursActifs -and $_ -ne "Administrateur" -and $_ -ne "Invité" }

# Désactiver les utilisateurs en trop et les ajouter au fichier résultat
$UtilisateursDesactives = @()
foreach ($utilisateurAD in $UtilisateursADaDesactiver) {
    Disable-ADAccount -Identity $utilisateurAD
    Write-Host "Utilisateur $utilisateurAD désactivé."
    $UtilisateursDesactives += $utilisateurAD
}

# Générer un fichier resultat.csv pour les utilisateurs désactivés
$cheminResultatCSV = "C:\Share\Donnee\resultat.csv"
$UtilisateursDesactives | ForEach-Object {
    [PSCustomObject]@{
        "Utilisateur désactivé" = $_
    }
} | Export-Csv -Path $cheminResultatCSV -Delimiter ";" -NoTypeInformation

Write-Host "Tous les utilisateurs inactifs ont été désactivés. Le résultat est enregistré dans resultat.csv."

# Afficher le nombre total d'utilisateurs désactivés
Write-Host "Nombre total d'utilisateurs désactivés : $($UtilisateursDesactives.Count)"
Write-Host "Utilisateurs actifs : $($NomsUtilisateursActifs -join ', ')"
Write-Host "Utilisateurs AD : $($NomsUtilisateursAD -join ', ')"
