rule SliverDetection
{
    strings:
        $exec_linux_string = "syscall/exec_linux.go"
        $transparent_string = "/sys/kernel/mm/transparent_hugepage/hpage_pmd_size"
    condition:
        $exec_linux_string or $transparent_string
}
rule CobaltDetection
{
    strings:
        $AA_string = "AA"
    condition:
        $AA_string
}
