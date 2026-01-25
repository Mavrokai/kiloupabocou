<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class DefaultController extends AbstractController
{
    #[Route('/', name: 'home')]
    public function index(): Response
    {
        return new Response(
            '<html><body><h1>Bienvenue sur Kiloupabocou !</h1><p>L\'infrastructure Docker fonctionne correctement.</p></body></html>'
        );
    }
}

